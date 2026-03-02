import boto3

def get_jwt_token(client_id, username, password, region='ca-central-1'):
    """
    Authenticates with Cognito using USER_PASSWORD_AUTH and returns the IdToken.
    """
    client = boto3.client('cognito-idp', region_name=region)
    try:
        response = client.initiate_auth(
            ClientId=client_id,
            AuthFlow='USER_PASSWORD_AUTH',
            AuthParameters={
                'USERNAME': username,
                'PASSWORD': password
            }
        )
        # The IdToken is typically used for API Authorization headers
        return response['AuthenticationResult']['IdToken']
    except Exception as e:
        print(f"❌ Cognito Authentication Error: {e}")
        return None