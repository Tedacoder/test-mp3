import urllib.request
import json
import config

def test():
    # Test config store name
    assert config.STORE_NAME == "ModernStore"

    # Test HTML view rendering config
    req = urllib.request.Request("http://127.0.0.1:5000/")
    with urllib.request.urlopen(req) as response:
        html = response.read().decode()
        assert "ModernStore POS" in html
        assert "Welcome to ModernStore!" in html

    # Add item and add to ticket
    data = json.dumps({"name": "Apple", "price": 1.5}).encode('utf-8')
    urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:5000/api/inventory", data=data, headers={'Content-Type': 'application/json'}))
    urllib.request.urlopen(urllib.request.Request("http://127.0.0.1:5000/api/ticket", data=json.dumps({"name": "Apple"}).encode('utf-8'), headers={'Content-Type': 'application/json'}))

    # Checkout Bank
    data = json.dumps({"payment_method": "bank"}).encode('utf-8')
    req = urllib.request.Request("http://127.0.0.1:5000/api/checkout", data=data, headers={'Content-Type': 'application/json'}, method="POST")
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['paid'] == 1.5
        assert res['method'] == 'bank'
        assert "deducted directly from customer bank" in res['message']

    print("All payment and config tests passed!")

test()
