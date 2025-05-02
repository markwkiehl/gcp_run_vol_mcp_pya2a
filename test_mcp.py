#
#   Written by:  Mark W Kiehl
#   http://mechatronicsolutionsllc.com/
#   http://www.savvysolutions.info/savvycodesolutions/

"""

Tests the MCP server running either locally as localhost, within a Docker container, or on Google Cloud Run.
When running locally as localhost (127.0.0.1), then set test_mcp() argument use_localhost=True, otherwise False.

See main.py for more details.

"""


# Define the script version in terms of Semantic Versioning (SemVer)
# when Git or other versioning systems are not employed.
__version__ = "0.0.0"
from pathlib import Path
print("'" + Path(__file__).stem + ".py'  v" + __version__)



def wait_for_server(url, tool_names, max_retries=10, retry_delay=0.1):
    """Waits for the server to become available by checking tool routes."""
    import requests
    import time
    import json  # Import the json module

    for _ in range(max_retries):
        all_tools_ready = True
        for tool_name in tool_names:
            try:
                check_url = f"{url}/tools/{tool_name}"
                response = requests.post(
                    check_url,
                    json={"expression": "2 + 2"}  # Or a relevant payload
                )
                if response.status_code == 200:
                    try:
                        json.loads(response.text)  # Validate JSON response
                    except json.JSONDecodeError:
                        print(f"Tool {tool_name}: Invalid JSON: {response.text}")
                        all_tools_ready = False
                        break  # No need to check other tools if one fails
                else:
                    print(f"Tool {tool_name}: Status {response.status_code}")
                    all_tools_ready = False
                    break
            except requests.exceptions.RequestException as e:
                print(f"Tool {tool_name}: Exception: {e}")
                all_tools_ready = False
                break
        if all_tools_ready:
            return True
        time.sleep(retry_delay)
    return False


def test_mcp(use_localhost:bool=True, cloud_run_url:str=None):

    import requests
    from time import perf_counter, sleep

    t_start_sec = perf_counter()

    if use_localhost == True:
        port = 8000     # Update with the port reported by main.py
        server_url = f"http://localhost:{port}"
    else:
        port = 8080     # For Docker container or Cloud Run
        if cloud_run_url is None: raise Exception("Argument cloud_run_url not passed to fn")
        server_url = f"{cloud_run_url}"
   
    print(f"\nserver_url: {server_url}")

    # IMPORTANT: Update list below with the names of the tools from main.py
    tool_names = ["calculator"]

    # Wait for the server to start
    # Only implement this for local development because it adds a considerable delay.
    # The tool implementation (test calculator) has a retry loop to manage a server delay.
    """
    print("\nWaiting for MCP server to start...")
    if not wait_for_server(server_url, tool_names):
        print("Error: MCP server did not start in time.")
        return
    print(f"{round(perf_counter()-t_start_sec,2)} sec elapsed")
    """

    # 4. Test the tools
    print("\n4. Testing MCP tools...")
    
    # Test calculator
    print("\nTesting calculator tool:")
    test_result = False
    # Allow up to 10 * 1 sec delay in the response of the MCP server.
    for i in range(10):
        try:
            calc_resp = requests.post(
                f"{server_url}/tools/calculator",
                json={"expression": "2 + 3 * 4"}
            )
            if calc_resp.status_code == 200:
                content = calc_resp.json().get("content", [])
                text = content[0].get("text") if content else "No content"
                print(f"Success! Result: {text}")
                test_result = True
                break
            else:
                #print(f"Failed: {calc_resp.status_code} - {calc_resp.text}")
                print(f"Failed: {calc_resp.status_code} .. waiting for the server to respond..")
                sleep(1)
        except Exception as e:
            print(f"Error: {e}")
            break
    print(f"{round(perf_counter()-t_start_sec,2)} sec elapsed")
    if test_result == False: print(f"MCD server not responding.  Check the URL and port  {server_url}")
    

if __name__ == "__main__":
    pass

    # If use_localhost=False, then YOU MUST UPDATE WITH THE GOOGLE CLOUD RUN URL.  
    cloud_run_url = "https://gcp-gcp-run-fastapi-mcp-EDITMEWITHYOURURL.a.run.app"

    # Set use_localhost=True to run locally using localhost (127.0.0.1).
    # Set use_localhost=False to run in a Docker container locally, or as a Cloud Run Service. 
    test_mcp(use_localhost=False, cloud_run_url=cloud_run_url)

