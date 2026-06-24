#!/usr/bin/env python3
import sys 
import argparse 
import boto3 
from botocore .exceptions import ClientError 

def log_info (msg ):
    print (f"\033[94m[INFO]\033[0m {msg }")

def log_success (msg ):
    print (f"\033[92m[PASS]\033[0m {msg }")

def log_failure (msg ):
    print (f"\033[91m[FAIL]\033[0m {msg }")

def check_security_groups (ec2_client ,tag_key ,tag_values ):
    log_info (f"Auditing Security Groups matching tag '{tag_key }' in {tag_values } for PCI-DSS compliance...")
    non_compliant_count =0 


    restricted_ports ={
    22 :"SSH",
    3389 :"RDP",
    5432 :"PostgreSQL",
    1514 :"Wazuh Agent",
    1515 :"Wazuh Enroll",
    9200 :"OpenSearch"
    }

    try :

        response =ec2_client .describe_security_groups (
        Filters =[
        {
        'Name':f'tag:{tag_key }',
        'Values':tag_values 
        }
        ]
        )

        sgs =response .get ('SecurityGroups',[])
        if not sgs :
            log_info (f"No security groups found matching tag '{tag_key }' in {tag_values }.")
            return 0 

        for sg in sgs :
            sg_id =sg ['GroupId']
            sg_name =sg ['GroupName']
            log_info (f"Checking Security Group: {sg_name } ({sg_id })")

            compliant =True 
            for rule in sg .get ('IpPermissions',[]):
                from_port =rule .get ('FromPort')
                to_port =rule .get ('ToPort')
                protocol =rule .get ('IpProtocol')


                for ip_range in rule .get ('IpRanges',[]):
                    cidr =ip_range .get ('CidrIp')
                    if cidr =='0.0.0.0/0':

                        if from_port is None or to_port is None or protocol =='-1':
                            log_failure (f"  SG {sg_id } allows ALL ports open to the public (0.0.0.0/0)!")
                            compliant =False 
                        else :
                            for port ,desc in restricted_ports .items ():
                                if from_port <=port <=to_port :
                                    log_failure (f"  SG {sg_id } allows public access to restricted port {port } ({desc })!")
                                    compliant =False 

            if compliant :
                log_success (f"  SG {sg_name } ({sg_id }) has no public ingress rules on restricted ports.")
            else :
                non_compliant_count +=1 

    except ClientError as e :
        log_failure (f"Failed to describe security groups: {e }")
        return 1 

    return non_compliant_count 

def check_s3_buckets (s3_client ,tag_key ,tag_values ):
    log_info (f"Auditing S3 Buckets matching tag '{tag_key }' in {tag_values } for PCI-DSS compliance...")
    non_compliant_count =0 

    try :
        response =s3_client .list_buckets ()
        buckets =response .get ('Buckets',[])

        for bucket in buckets :
            bucket_name =bucket ['Name']


            try :
                tag_response =s3_client .get_bucket_tagging (Bucket =bucket_name )
                tags ={t ['Key']:t ['Value']for t in tag_response .get ('TagSet',[])}
            except ClientError as e :

                if e .response ['Error']['Code']in ('NoSuchTagSet','AccessDenied'):
                    tags ={}
                else :
                    raise e 

            value =tags .get (tag_key ,'')

            if value in tag_values :
                log_info (f"Checking S3 Bucket: {bucket_name }")
                compliant =True 


                try :
                    s3_client .get_bucket_encryption (Bucket =bucket_name )
                except ClientError as e :
                    if e .response ['Error']['Code']=='ServerSideEncryptionConfigurationNotFoundError':
                        log_failure (f"  Bucket {bucket_name } does not have default Server-Side Encryption enabled!")
                        compliant =False 
                    else :
                        log_failure (f"  Could not check encryption for {bucket_name }: {e }")
                        compliant =False 


                try :
                    pab =s3_client .get_public_access_block (Bucket =bucket_name )
                    config =pab .get ('PublicAccessBlockConfiguration',{})
                    if not (config .get ('BlockPublicAcls')and config .get ('IgnorePublicAcls')and 
                    config .get ('BlockPublicPolicy')and config .get ('RestrictPublicBuckets')):
                        log_failure (f"  Bucket {bucket_name } does not have all Public Access Blocks enabled!")
                        compliant =False 
                except ClientError as e :
                    if e .response ['Error']['Code']=='NoSuchPublicAccessBlockConfiguration':
                        log_failure (f"  Bucket {bucket_name } has no Public Access Block configuration!")
                        compliant =False 
                    else :
                        log_failure (f"  Could not check public access block for {bucket_name }: {e }")
                        compliant =False 

                if compliant :
                    log_success (f"  Bucket {bucket_name } is secure and encrypted.")
                else :
                    non_compliant_count +=1 

    except ClientError as e :
        log_failure (f"Failed to list S3 buckets: {e }")
        return 1 

    return non_compliant_count 

def check_eks_clusters (eks_client ,tag_key ,tag_values ):
    log_info (f"Auditing EKS Clusters matching tag '{tag_key }' in {tag_values } for PCI-DSS compliance...")
    non_compliant_count =0 

    try :
        response =eks_client .list_clusters ()
        clusters =response .get ('clusters',[])

        for name in clusters :
            try :
                desc =eks_client .describe_cluster (name =name )
                cluster =desc .get ('cluster',{})
                tags =cluster .get ('tags',{})
            except ClientError as e :
                log_failure (f"  Could not describe cluster {name }: {e }")
                continue 

            value =tags .get (tag_key ,'')
            if value in tag_values :
                log_info (f"Checking EKS Cluster: {name }")
                compliant =True 


                logging =cluster .get ('logging',{}).get ('clusterLogging',[])
                enabled_types =[]
                for entry in logging :
                    if entry .get ('enabled'):
                        enabled_types .extend (entry .get ('types',[]))

                required_logs ={'api','audit','authenticator','controllerManager','scheduler'}
                missing_logs =required_logs -set (enabled_types )

                if missing_logs :
                    log_failure (f"  Cluster {name } is missing the following audit logs: {list (missing_logs )}")
                    compliant =False 

                if compliant :
                    log_success (f"  Cluster {name } logging configuration is compliant.")
                else :
                    non_compliant_count +=1 

    except ClientError as e :
        log_failure (f"Failed to list EKS clusters: {e }")
        return 1 

    return non_compliant_count 

def main ():
    parser =argparse .ArgumentParser (description ="Audit active AWS resources for PCI-DSS compliance.")
    parser .add_argument (
    "--tag-key",
    default ="Project",
    help ="The tag key to filter resources by (default: Project)"
    )
    parser .add_argument (
    "--tag-value",
    action ="append",
    dest ="tag_values",
    help ="The tag value(s) to filter resources by (can be specified multiple times)"
    )

    args =parser .parse_args ()


    tag_key =args .tag_key 
    tag_values =args .tag_values if args .tag_values else ["aws-eks-openTel-pci-dss","financeguard"]


    session =boto3 .Session ()
    ec2_client =session .client ('ec2',region_name ='us-east-1')
    s3_client =session .client ('s3')
    eks_client =session .client ('eks',region_name ='us-east-1')

    failed_checks =0 

    failed_checks +=check_security_groups (ec2_client ,tag_key ,tag_values )
    print ("-"*60 )
    failed_checks +=check_s3_buckets (s3_client ,tag_key ,tag_values )
    print ("-"*60 )
    failed_checks +=check_eks_clusters (eks_client ,tag_key ,tag_values )
    print ("-"*60 )

    if failed_checks >0 :
        log_failure (f"PCI-DSS Audit finished: {failed_checks } compliance violations detected.")
        sys .exit (1 )
    else :
        log_success ("PCI-DSS Audit finished: All scanned resources are compliant.")
        sys .exit (0 )

if __name__ =="__main__":
    main ()
