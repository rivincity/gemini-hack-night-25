# ngrok Setup Verification ✅

## Backend Configuration

**File**: `backend/run.py`

✅ Flask runs on: `0.0.0.0:5000` (all interfaces)
✅ ngrok tunnels: `https://850a286ace35.ngrok-free.app` → `localhost:5000`

## Frontend Configuration

**File**: `Roam/Roam/Services/APIConfig.swift` (Line 12)

✅ Base URL: `https://850a286ace35.ngrok-free.app`
✅ API Version: `/api`

## All API Endpoints (Verified)

### Authentication Endpoints
- ✅ `https://850a286ace35.ngrok-free.app/api/auth/login`
- ✅ `https://850a286ace35.ngrok-free.app/api/auth/signup`
- ✅ `https://850a286ace35.ngrok-free.app/api/auth/logout`
- ✅ `https://850a286ace35.ngrok-free.app/api/auth/me`

### Vacation Endpoints
- ✅ `https://850a286ace35.ngrok-free.app/api/vacations`
- ✅ `https://850a286ace35.ngrok-free.app/api/vacations/{id}`

### Photo Endpoints
- ✅ `https://850a286ace35.ngrok-free.app/api/photos/upload`
- ✅ `https://850a286ace35.ngrok-free.app/api/photos/upload/batch`

### AI Endpoints
- ✅ `https://850a286ace35.ngrok-free.app/api/ai/generate-itinerary`
- ✅ `https://850a286ace35.ngrok-free.app/api/ai/analyze-photo`

### Friends Endpoints
- ✅ `https://850a286ace35.ngrok-free.app/api/friends`
- ✅ `https://850a286ace35.ngrok-free.app/api/friends/add`
- ✅ `https://850a286ace35.ngrok-free.app/api/friends/requests`

## Other URLs Found (Not Changed - These are correct)

### External URLs (Google Services)
- Google Flights: `https://www.google.com/flights` (PinDetailViewController.swift:436)
- Google Search: `https://www.google.com/search` (PinDetailViewController.swift:448)
- Article links: `https://www.google.com/search` (PinDetailViewController.swift:335-337)

### Placeholder URLs (Not real endpoints)
- Terms of Service: `https://roamapp.com/terms` (SettingsView.swift:107)
- Privacy Policy: `https://roamapp.com/privacy` (SettingsView.swift:108)
- Support: `https://roamapp.com/support` (SettingsView.swift:133)

## How to Test

### 1. Start Backend (Terminal 1)
```bash
cd backend
python run.py
```

**Expected Output**:
```
✅ Configuration validated successfully
   SUPABASE_URL: https://nmuxndxoaaychylcqwsw.s...
   GEMINI_API_KEY: AIzaSyAKk7F_jTL56mlj...

🚀 Starting Roam API server on 0.0.0.0:5000
   Debug mode: True
   Local: http://localhost:5000/api/health
   ngrok: https://850a286ace35.ngrok-free.app/api/health

 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.x.x:5000
```

### 2. Verify ngrok is Running (Terminal 2)
```bash
ngrok http 5000
```

**Expected Output**:
```
Forwarding  https://850a286ace35.ngrok-free.app -> http://localhost:5000
```

### 3. Test Backend via ngrok
```bash
curl https://850a286ace35.ngrok-free.app/api/health
```

**Expected Response**:
```json
{"status":"ok","message":"Roam API is running"}
```

### 4. Run iOS App
1. Build and run in Xcode
2. Watch console for API calls
3. All requests should go to `https://850a286ace35.ngrok-free.app/api/*`

## Verification Checklist

- [x] Backend runs on `0.0.0.0:5000`
- [x] ngrok tunnel is active
- [x] iOS app uses ngrok URL (`https://850a286ace35.ngrok-free.app`)
- [x] No localhost URLs in iOS code
- [x] All API endpoints use `baseURL` from APIConfig
- [x] External URLs (Google) are unchanged
- [x] Placeholder URLs are unchanged

## Request Flow

```
iOS App
   ↓
   Makes request to: https://850a286ace35.ngrok-free.app/api/auth/login
   ↓
ngrok
   ↓
   Forwards to: http://localhost:5000/api/auth/login
   ↓
Flask Backend (runs on 0.0.0.0:5000)
   ↓
   Processes request, returns response
   ↓
ngrok
   ↓
   Forwards response back
   ↓
iOS App receives response
```

## Common Issues & Solutions

### Issue: ngrok URL Changed
**Solution**: Update `APIConfig.swift` line 12 with new URL

### Issue: "Connection refused"
**Check**:
1. Is Flask running? (`python run.py`)
2. Is ngrok running? (`ngrok http 5000`)
3. Do the URLs match?

### Issue: "Tunnel not found"
**Solution**: Restart ngrok, update URL in APIConfig.swift

### Issue: iOS can't connect
**Check**:
1. Rebuild iOS app after changing APIConfig.swift
2. Check ngrok is forwarding correctly
3. Verify Flask is running

## Testing Individual Endpoints

### Test Health Check
```bash
curl https://850a286ace35.ngrok-free.app/api/health
```

### Test Signup (from command line)
```bash
curl -X POST https://850a286ace35.ngrok-free.app/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123",
    "name": "Test User"
  }'
```

### Test Login
```bash
curl -X POST https://850a286ace35.ngrok-free.app/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "password123"
  }'
```

## Success Indicators

When everything is working:

1. ✅ Backend shows Flask is running
2. ✅ ngrok shows "Session Status: online"
3. ✅ Curl to health endpoint returns 200 OK
4. ✅ iOS console shows: `🔗 DEBUG: Endpoint: https://850a286ace35.ngrok-free.app/api/*`
5. ✅ Backend console shows incoming requests
6. ✅ ngrok web interface shows request logs (http://127.0.0.1:4040)

## ngrok Web Interface

Visit `http://127.0.0.1:4040` to see:
- All requests going through the tunnel
- Request/response details
- Timing information
- Useful for debugging!

---

## ⚠️ IMPORTANT NOTES

1. **ngrok URLs change** when you restart ngrok (unless you have a paid account)
2. **Always update** APIConfig.swift if ngrok URL changes
3. **Rebuild iOS app** after changing APIConfig.swift
4. **Keep both terminals open** (Flask and ngrok) while testing
5. **Free ngrok has rate limits** - be mindful during testing

---

## Everything is Ready! 🚀

Your iOS app will now connect to your backend through the ngrok tunnel. Test by:
1. Starting Flask: `python run.py`
2. Verifying ngrok is running
3. Running iOS app in Xcode
4. Trying to sign up / log in
5. Creating a vacation with photos

All API calls from iOS will go through `https://850a286ace35.ngrok-free.app` → Flask backend!
