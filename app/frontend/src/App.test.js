import { render, screen } from '@testing-library/react';
import '@testing-library/jest-dom';
import App from './App';


test('renders React API Client header', () => {
  render(<App />);
  const headerElement = screen.getByText(/React API Client/i);
  expect(headerElement).toBeInTheDocument();
});
