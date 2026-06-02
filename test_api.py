import urllib.request
import json

def test():
    # Test HTML view
    req = urllib.request.Request("http://127.0.0.1:5000/")
    with urllib.request.urlopen(req) as response:
        assert response.status == 200

    # Add inventory
    data = json.dumps({"name": "Apple", "price": 1.5}).encode('utf-8')
    req = urllib.request.Request("http://127.0.0.1:5000/api/inventory", data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['inventory']['Apple'] == 1.5

    # Get inventory
    req = urllib.request.Request("http://127.0.0.1:5000/api/inventory")
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['Apple'] == 1.5

    # Add to ticket
    data = json.dumps({"name": "Apple"}).encode('utf-8')
    req = urllib.request.Request("http://127.0.0.1:5000/api/ticket", data=data, headers={'Content-Type': 'application/json'})
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['total'] == 1.5

    # Checkout
    req = urllib.request.Request("http://127.0.0.1:5000/api/checkout", data=b'{}', headers={'Content-Type': 'application/json'}, method="POST")
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['paid'] == 1.5

    print("All tests passed!")

test()
