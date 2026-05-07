import urllib.request
import urllib.error
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

    # Add inventory - Missing Name or Price
    data = json.dumps({"name": "Banana"}).encode('utf-8') # missing price
    req = urllib.request.Request("http://127.0.0.1:5000/api/inventory", data=data, headers={'Content-Type': 'application/json'})
    try:
        urllib.request.urlopen(req)
        assert False, "Expected 400 Bad Request for missing price"
    except urllib.error.HTTPError as e:
        assert e.code == 400
        res = json.loads(e.read().decode())
        assert res['error'] == 'Missing name or price'

    data = json.dumps({"price": 2.0}).encode('utf-8') # missing name
    req = urllib.request.Request("http://127.0.0.1:5000/api/inventory", data=data, headers={'Content-Type': 'application/json'})
    try:
        urllib.request.urlopen(req)
        assert False, "Expected 400 Bad Request for missing name"
    except urllib.error.HTTPError as e:
        assert e.code == 400
        res = json.loads(e.read().decode())
        assert res['error'] == 'Missing name or price'

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
    req = urllib.request.Request("http://127.0.0.1:5000/api/checkout", data=json.dumps({}).encode('utf-8'), headers={'Content-Type': 'application/json'}, method="POST")
    with urllib.request.urlopen(req) as response:
        res = json.loads(response.read().decode())
        assert res['paid'] == 1.5

    print("All tests passed!")

test()
