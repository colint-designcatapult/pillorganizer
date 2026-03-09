import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';

class AmplifyService {
  static const amplifyconfig = ''' {
    "UserAgent": "aws-amplify-cli/2.0",
    "Version": "1.0",
    "auth": {
        "plugins": {
            "awsCognitoAuthPlugin": {
                "CognitoUserPool": {
                    "Default": {
                        "PoolId": "ca-central-1_PHR6msiks",
                        "AppClientId": "2ofl5qi7qfqopfph6dqff0dl61",
                        "Region": "ca-central-1"
                    }
                },
                "Auth": {
                    "Default": {
                        "OAuth": {
                            "WebDomain": "healthesolutions.auth.ca-central-1.amazoncognito.com",
                            "AppClientId": "2ofl5qi7qfqopfph6dqff0dl61",
                            "SignInRedirectURI": "jct.pillorganizer.pills://callback",
                            "SignOutRedirectURI": "jct.pillorganizer.pills://signout",
                            "Scopes": [
                                "profile",
                                "openid"
                            ]
                        }
                    }
                }
            }
        }
    }
}''';

  Future<void> configureAmplify() async {
    try {
      await Amplify.addPlugin(AmplifyAuthCognito());
      await Amplify.configure(amplifyconfig);
      safePrint('Successfully configured');
    } on Exception catch (e) {
      safePrint('Error configuring Amplify: $e');
    }
  }

  Future<bool> signInWithWebUI() async {
    try {
      final result = await Amplify.Auth.signInWithWebUI();
      safePrint('Sign in result: $result');
      return result.isSignedIn;
    } on AuthException catch (e) {
      safePrint('Error signing in: ${e.message}');
      return false;
    }
  }

  Future<String?> getIdToken() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = result as CognitoAuthSession;
      return cognitoSession.userPoolTokensResult.value.idToken.raw;
    } on AuthException catch (e) {
      safePrint('Error retrieving auth session: ${e.message}');
      return null;
    }
  }

  Future<String?> getAccessToken() async {
    try {
      final result = await Amplify.Auth.fetchAuthSession();
      final cognitoSession = result as CognitoAuthSession;
      return cognitoSession.userPoolTokensResult.value.accessToken.raw;
    } on AuthException catch (e) {
      safePrint('Error retrieving auth session: ${e.message}');
      return null;
    }
  }
}
