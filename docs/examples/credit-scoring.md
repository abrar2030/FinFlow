# Credit Scoring Example

ML-based credit scoring workflow using FinFlow.

---

## Calculate Credit Score

```python
import requests

def calculate_credit_score(applicant_data):
    """Calculate credit score for loan applicant"""
    url = 'http://localhost:3005/api/credit/score'
    headers = {'Authorization': f'Bearer {token}'}

    response = requests.post(url, json=applicant_data, headers=headers)
    response.raise_for_status()

    return response.json()

# Example applicant data
applicant = {
    'income': 75000,
    'numInvoices': 45,
    'avgCashflow': 5000,
    'delinquencies': 0
}

result = calculate_credit_score(applicant)
print(f"Credit Score: {result['credit_score']:.2f}")
print(f"Risk Category: {result['risk_category']}")
```

---

## Generate Loan Offer

```python
def generate_loan_offer(applicant_id, credit_score, requested_amount):
    """Generate personalized loan offer"""
    url = 'http://localhost:3005/api/credit/loan-offer'
    headers = {'Authorization': f'Bearer {token}'}

    data = {
        'applicantId': applicant_id,
        'creditScore': credit_score,
        'requestedAmount': requested_amount
    }

    response = requests.post(url, json=data, headers=headers)
    response.raise_for_status()

    return response.json()

# Generate offer
offer = generate_loan_offer('user-uuid', 0.78, 50000)

if offer['approved']:
    print(f"✓ Loan Approved")
    print(f"Amount: ${offer['offeredAmount']:,.2f}")
    print(f"Interest Rate: {offer['interestRate']}%")
    print(f"Term: {offer['termMonths']} months")
    print(f"Monthly Payment: ${offer['monthlyPayment']:,.2f}")
else:
    print("✗ Loan Declined")
```

---

For more examples, see [API Documentation](../API.md#credit-engine-api).
