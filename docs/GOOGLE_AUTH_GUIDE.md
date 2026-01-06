# Guía de Autenticación con Google

Documentación para implementar Google Sign-In en iOS (Swift) y Android (Kotlin).

## Flujo General

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Usuario   │────▶│  Google SDK │────▶│  Tu Backend │
│  (tap btn)  │     │  (idToken)  │     │  (validar)  │
└─────────────┘     └─────────────┘     └─────────────┘
```

1. Usuario toca "Continuar con Google"
2. Google SDK muestra pantalla de selección de cuenta
3. Usuario autoriza → SDK devuelve `idToken`
4. Envías `idToken` a tu backend para validar y crear sesión

---

## Configuración en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un proyecto o selecciona uno existente
3. Ve a **APIs & Services > Credentials**
4. Crea credenciales **OAuth 2.0 Client ID**:
   - Para iOS: tipo "iOS", agrega tu Bundle ID
   - Para Android: tipo "Android", agrega tu package name y SHA-1

---

## iOS (Swift)

### 1. Agregar dependencia

En Xcode, ve a **File > Add Package Dependencies** y agrega:
```
https://github.com/google/GoogleSignIn-iOS
```

### 2. Configurar Info.plist

Agrega el URL scheme para el callback de Google:

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.TU_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 3. Código de implementación

```swift
import GoogleSignIn
import GoogleSignInSwift

// En tu View o ViewController
func handleGoogleSignIn() {
    // Obtener el rootViewController
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
          let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
        print("Error: Root View Controller not found")
        return
    }

    // Configurar Google Sign-In con tu Client ID
    GIDSignIn.sharedInstance.configuration = GIDConfiguration(
        clientID: "TU_CLIENT_ID.apps.googleusercontent.com"
    )

    // Iniciar el flujo de login
    GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { signInResult, error in
        // Manejar error
        guard let result = signInResult else {
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
            }
            return
        }
        
        // Obtener el idToken (esto es lo que envías a tu backend)
        guard let idToken = result.user.idToken?.tokenString else {
            print("Error: idToken vacío")
            return
        }

        // Datos útiles del usuario
        let email = result.user.profile?.email
        let name = result.user.profile?.name
        let authorizationCode = result.serverAuthCode // Opcional, para refresh tokens

        print("Login exitoso: \(email ?? "sin email")")
        
        // Enviar idToken a tu backend
        Task {
            await sendTokenToBackend(idToken: idToken)
        }
    }
}
```

### 4. Manejar el callback en AppDelegate/SceneDelegate

```swift
// En tu App.swift o SceneDelegate
func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
    return GIDSignIn.sharedInstance.handle(url)
}
```

---

## Android (Kotlin)

### 1. Agregar dependencias

En `build.gradle.kts` (app level):

```kotlin
dependencies {
    implementation("com.google.android.gms:play-services-auth:21.0.0")
    // Para Credential Manager (recomendado en Android 14+)
    implementation("androidx.credentials:credentials:1.3.0")
    implementation("androidx.credentials:credentials-play-services-auth:1.3.0")
    implementation("com.google.android.libraries.identity.googleid:googleid:1.1.1")
}
```

### 2. Configurar strings.xml

```xml
<resources>
    <string name="default_web_client_id">TU_CLIENT_ID.apps.googleusercontent.com</string>
</resources>
```

### 3. Código de implementación (Credential Manager - Recomendado)

```kotlin
import androidx.credentials.CredentialManager
import androidx.credentials.GetCredentialRequest
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential

class GoogleAuthManager(private val context: Context) {
    
    private val credentialManager = CredentialManager.create(context)
    
    suspend fun signIn(activity: Activity): Result<String> {
        return try {
            // Configurar la solicitud de Google ID
            val googleIdOption = GetGoogleIdOption.Builder()
                .setFilterByAuthorizedAccounts(false) // Mostrar todas las cuentas
                .setServerClientId(context.getString(R.string.default_web_client_id))
                .build()

            val request = GetCredentialRequest.Builder()
                .addCredentialOption(googleIdOption)
                .build()

            // Mostrar el selector de cuentas
            val result = credentialManager.getCredential(
                request = request,
                context = activity
            )

            // Extraer el token
            val credential = result.credential
            val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
            val idToken = googleIdTokenCredential.idToken

            // Datos del usuario
            val email = googleIdTokenCredential.id
            val displayName = googleIdTokenCredential.displayName

            Log.d("GoogleAuth", "Login exitoso: $email")
            
            Result.success(idToken)
        } catch (e: Exception) {
            Log.e("GoogleAuth", "Error: ${e.message}")
            Result.failure(e)
        }
    }
}
```

### 4. Uso en Activity/Fragment

```kotlin
class LoginActivity : AppCompatActivity() {
    
    private val googleAuthManager by lazy { GoogleAuthManager(this) }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        binding.googleSignInButton.setOnClickListener {
            signInWithGoogle()
        }
    }
    
    private fun signInWithGoogle() {
        lifecycleScope.launch {
            googleAuthManager.signIn(this@LoginActivity)
                .onSuccess { idToken ->
                    // Enviar idToken a tu backend
                    sendTokenToBackend(idToken)
                }
                .onFailure { error ->
                    Toast.makeText(this@LoginActivity, 
                        "Error: ${error.message}", 
                        Toast.LENGTH_SHORT
                    ).show()
                }
        }
    }
    
    private suspend fun sendTokenToBackend(idToken: String) {
        // Tu lógica para enviar el token al backend
    }
}
```

### Alternativa: Google Sign-In Legacy (para Android < 14)

```kotlin
import com.google.android.gms.auth.api.signin.GoogleSignIn
import com.google.android.gms.auth.api.signin.GoogleSignInOptions

class GoogleAuthLegacy(private val activity: Activity) {
    
    private val gso = GoogleSignInOptions.Builder(GoogleSignInOptions.DEFAULT_SIGN_IN)
        .requestIdToken(activity.getString(R.string.default_web_client_id))
        .requestEmail()
        .build()
    
    private val googleSignInClient = GoogleSignIn.getClient(activity, gso)
    
    fun signIn(launcher: ActivityResultLauncher<Intent>) {
        val signInIntent = googleSignInClient.signInIntent
        launcher.launch(signInIntent)
    }
    
    fun handleResult(data: Intent?): String? {
        val task = GoogleSignIn.getSignedInAccountFromIntent(data)
        return try {
            val account = task.getResult(ApiException::class.java)
            account.idToken
        } catch (e: ApiException) {
            Log.e("GoogleAuth", "Error code: ${e.statusCode}")
            null
        }
    }
}
```

---

## Backend: Validar el idToken

El `idToken` es un JWT firmado por Google. Tu backend debe:

1. Verificar la firma del token
2. Validar el `aud` (audience) coincida con tu Client ID
3. Verificar que no esté expirado
4. Extraer el email/sub para identificar al usuario

Ejemplo con Node.js:

```javascript
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client(CLIENT_ID);

async function verifyGoogleToken(idToken) {
    const ticket = await client.verifyIdToken({
        idToken: idToken,
        audience: CLIENT_ID
    });
    const payload = ticket.getPayload();
    return {
        email: payload.email,
        name: payload.name,
        sub: payload.sub // ID único del usuario en Google
    };
}
```

---

## Resumen de diferencias iOS vs Android

| Aspecto | iOS | Android |
|---------|-----|---------|
| SDK | GoogleSignIn-iOS | play-services-auth / Credential Manager |
| Configuración | Info.plist URL Scheme | strings.xml + SHA-1 |
| Resultado | `GIDSignInResult` | `GoogleIdTokenCredential` |
| Token | `result.user.idToken?.tokenString` | `credential.idToken` |

---

## Tips

- Usa el mismo `Client ID` (Web) para validar en el backend
- El `idToken` expira en ~1 hora, no lo guardes
- Para refresh tokens, necesitas el `serverAuthCode`
- Siempre valida el token en tu backend, nunca confíes solo en el cliente
