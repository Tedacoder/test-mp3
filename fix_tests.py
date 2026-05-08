# The tests failed because:
# test_api.py line 34 passes empty bytes as data for POST. Flask 3.1+ handles empty POST data on application/json content type as Bad Request 400.
# We change it to send empty JSON `{}`.
with open('test_api.py', 'r') as f:
    c = f.read()
    c = c.replace("data=b''", "data=b'{}'")
with open('test_api.py', 'w') as f:
    f.write(c)
