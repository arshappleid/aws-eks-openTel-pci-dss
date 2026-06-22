# Network Routing Architecture

This diagram illustrates exactly how traffic flows from your isolated EKS Nodes in a Spoke VPC, out to the internet, and securely back again through your centralized DMZ (Inspection) VPC.

```mermaid
graph TD
    subgraph "Spoke VPC (e.g., Stage Backend)"
        EKS["EKS Node<br>(Private Subnet: 10.x.x.x)"]
        SpokeRT["Spoke Route Table<br>0.0.0.0/0 -> TGW Attachment"]
    end

    subgraph "Central Transit Gateway (TGW)"
        TGW_Spoke_RT["TGW Spoke Route Table<br>0.0.0.0/0 -> DMZ Attachment"]
        TGW_DMZ_RT["TGW Inspection Route Table<br>10.0.0.0/8 -> Spoke Attachments"]
    end

    subgraph "DMZ / Inspection VPC (Shared)"
        DMZ_Priv_RT["DMZ Private Route Table<br>0.0.0.0/0 -> NAT GW<br>10.0.0.0/8 -> TGW"]
        NAT["NAT Gateway<br>(Public Subnet)"]
        DMZ_Pub_RT["DMZ Public Route Table<br>0.0.0.0/0 -> IGW<br>10.0.0.0/8 -> TGW"]
        IGW["Internet Gateway"]
    end

    Internet(("Public Internet<br>(e.g., AWS ECR)"))

    %% Outbound Flow (Dotted lines)
    EKS -.->|1. Outbound Request| SpokeRT
    SpokeRT -.->|2. Forwards to TGW| TGW_Spoke_RT
    TGW_Spoke_RT -.->|3. Forwards to DMZ| DMZ_Priv_RT
    DMZ_Priv_RT -.->|4. Routes to NAT| NAT
    NAT -.->|5. NAT translates IP| DMZ_Pub_RT
    DMZ_Pub_RT -.->|6. Exits VPC| IGW
    IGW -.->|7. Request| Internet

    %% Return Flow (Thick lines)
    Internet ==>|8. Response| IGW
    IGW ==>|9. Forwards to NAT| NAT
    NAT ==>|10. Reverse Translation| DMZ_Pub_RT
    DMZ_Pub_RT ==>|11. 10.0.0.0/8 -> TGW| TGW_DMZ_RT
    TGW_DMZ_RT ==>|12. TGW evaluates route| SpokeRT
    SpokeRT ==>|13. Final Delivery| EKS

    classDef vpc fill:#f9f9f9,stroke:#333,stroke-width:2px;
    classDef aws fill:#FF9900,stroke:#232F3E,stroke-width:2px,color:black;
    class EKS,NAT,IGW aws;
```

### The Outbound Journey (Egress)
1. Your EKS Node tries to reach `0.0.0.0/0` (the internet).
2. The Spoke VPC Route Table sees the default route we just added and sends the packet to the Transit Gateway.
3. The Transit Gateway receives the packet, looks at the *Spoke Route Table*, and sends `0.0.0.0/0` to the DMZ Attachment.
4. The DMZ Private Route Table receives it and routes it to the NAT Gateway.
5. The NAT Gateway masks the internal IP address and sends it out the Internet Gateway to the web.

### The Return Journey (Ingress)
1. The internet responds, and the packet arrives at the Internet Gateway.
2. It hits the NAT Gateway, which un-masks the IP back to the original `10.x.x.x` EKS Node address.
3. **(The Bonus Fix):** The DMZ Public Route Table sees the destination is `10.x.x.x`, matches the `10.0.0.0/8` route we added, and fires the packet back to the Transit Gateway.
4. The Transit Gateway uses the *Inspection Route Table* to figure out exactly which Spoke VPC the `10.x.x.x` IP belongs to.
5. The packet drops into the Spoke VPC and arrives safely at the EKS Node.
