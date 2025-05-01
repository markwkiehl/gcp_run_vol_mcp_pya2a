#
#   Written by:  Mark W Kiehl
#   http://mechatronicsolutionsllc.com/
#   http://www.savvysolutions.info/savvycodesolutions/


"""
LangChain Tools → MCP: Expose LangChain Tool as MCP Endpoint

This script converts a simple custom LangChain tool to a standardized MCP endpoint, making it accessible to any MCP-compatible client.
The script is inspired by an article by Manoj Desai "Python A2A, MCP, and LangChain: Engineering the Next Generation of Modular GenAI Systems"
available at: https://medium.com/@the_manoj_desai/python-a2a-mcp-and-langchain-engineering-the-next-generation-of-modular-genai-systems-326a3e94efae

The article by Manoj Desai used localhost to create one or more MCP servers.  I adapted his example so that it both works as a localhost MCP
server, OR within a Docker container, OR deployed as Google Cloud Run Service.  

This script is based on the use of the Python library "python-a2a' created by Manoj Desai and others. 
Python A2A (python-a2a) is a powerful, easy-to-use library for implementing Google's [Agent-to-Agent (A2A) protocol](https://google.github.io/A2A/). 
https://github.com/themanojdesai/python-a2a
https://python-a2a.readthedocs.io/en/latest/
pip install python-a2a


Related articles by the same author:
https://medium.com/@manoj-desai/meet-google-a2a-the-protocol-that-will-revolutionize-multi-agent-ai-systems-f9ee7e72d20d
https://medium.com/@the_manoj_desai/how-agent-cards-tasks-transform-multi-agent-development-in-agent-to-agent-a2a-protocol-77d0a782c4fb
https://medium.com/@the_manoj_desai/the-power-duo-how-a2a-mcp-let-you-build-practical-ai-systems-today-9c19064b027b
https://medium.com/@the_manoj_desai/python-a2a-mcp-and-langchain-engineering-the-next-generation-of-modular-genai-systems-326a3e94efae
https://medium.com/@the_manoj_desai/smart-routing-the-hidden-secret-behind-10x-more-powerful-ai-systems-bd4258d6813a

"""

# Define the script version in terms of Semantic Versioning (SemVer)
# when Git or other versioning systems are not employed.
__version__ = "0.0.0"
from pathlib import Path
print("'" + Path(__file__).stem + ".py'  v" + __version__)



# Find an available port
def find_available_port(start_port=8000, max_tries=100):
    """Find an available localhost port starting from start_port"""
    import socket
    for port in range(start_port, start_port + max_tries):
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.bind(('localhost', port))
            sock.close()
            return port
        except OSError:
            continue
    return start_port + 1000


def langchain_to_mcp(use_localhost:bool=True):
    """
    LangChain Tools → MCP: Expose LangChain Tool as MCP Endpoint

    This script converts a simple custom LangChain tool to a standardized MCP endpoint, making it accessible to any MCP-compatible client.

    This script uses the Python library "python-a2a' created by Manoj Desai and others. 
    Python A2A (python-a2a) is a powerful, easy-to-use library for implementing Google's [Agent-to-Agent (A2A) protocol](https://google.github.io/A2A/). 
    https://github.com/themanojdesai/python-a2a
    https://python-a2a.readthedocs.io/en/latest/
    pip install python-a2a


    Arguments:
        use_localhost   True - Uses localhost (127.0.0.1).
                        False - When deployed in a Docker container or as a Google Cloud Run Service
                        
    """

    # Import required components
    try:
        from langchain.tools import Tool
        from python_a2a.langchain import to_mcp_server
        from time import sleep
        import os
    except ImportError as e:
        print(f"Error importing components: {e}")
        print('Install with: pip install python-a2a')
        return 1
    
    
    print("\nLangChain to MCP Example with Custom Tools")
        
    # 1. Create LangChain tools
    print("\n1. Creating LangChain tools...")
    
    # Custom calculator tool
    def calculator(expression: str) -> str:
        """Evaluate a mathematical expression"""
        try:
            result = eval(expression)
            return f"Result: {expression} = {result}"
        except Exception as e:
            return f"Error: {e}"
    
    # Create the LangChain tool
    calculator_tool = Tool(
        name="calculator",
        description="Evaluate a mathematical expression",
        func=calculator
    )
    
    # Create a list of tools
    tools = [calculator_tool]
    print(f"Created {len(tools)} tools:")
    
    # Print actual tool names for reference
    print("Tool names for reference:")
    for tool in tools:
        print(f"  • {tool.name}: {tool.description}")
    
    # 2. Convert to MCP server
    print("\n2. Converting to MCP server...")
    try:
        mcp_server = to_mcp_server(tools)
        print("Conversion successful")
        
        # Print tools
        mcp_tools = mcp_server.get_tools()
        print(f"Available MCP tools: {len(mcp_tools)}")
        for tool in mcp_tools:
            print(f"  • {tool['name']}: {tool['description']}")
    except Exception as e:
        print(f"Conversion failed: {e}")
        return None
    
    #print(f"{mcp_server.metadata}")     # {'name': 'LangChain Tools', 'version': '1.0.0', 'description': 'MCP server exposing LangChain tools', 'capabilities': ['tools', 'resources']}
    #print(f"{mcp_server.description}")  # MCP server exposing LangChain tools
    #print(f"{mcp_server.name}")         # LangChain Tools


    # 3. Start the server in the main thread

    # If use_localhost == True, then the first locally available port will be assigned (typically 8000).
    # If use_localhost == False, then running in a local Docker container or on Cloud Run.
    #   Use the PORT defined from the environment variable (when run in Docker or Cloud Run), or 8080.
    #   Note that Cloud Run injects the PORT environment variable into your container with the value of 8080, and your HTTP server should bind to this port. 
    #   For external access, Cloud Run services are typically exposed through standard HTTPS (port 443) and HTTP (port 80) via the automatically provisioned service URL.
    if use_localhost == True:
        port = find_available_port()
        host = "127.0.0.1"
    else:
        port = int(os.environ.get("PORT", 8080))  # Get port from env (8080) or default to 8080
        host = "0.0.0.0"

    print(f"\n3. Starting MCP server on {host}  port {port}...")
    mcp_server.run(host=host, port=port)  # Server runs in the main thread

    if use_localhost == True:
        # Keep the main thread alive (for localhost only)
        while True:
            # Sleep for a short interval to reduce CPU usage
            sleep(1)  


    # See script "test_mcp.py" for how to access the MCP and test the tool(s).


if __name__ == "__main__":
    pass

    # Set use_localhost=True to run locally using localhost (127.0.0.1)
    # Set use_localhost=False to run in a Docker container locally, or as a Cloud Run Service. 
    langchain_to_mcp(use_localhost=False)

    # See script "test_mcp.py" for how to access the MCP and test the tool(s).