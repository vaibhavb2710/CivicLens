# Quick Test Instructions

## To test without SMS issues:

### Use Test Phone Numbers (No SMS Required):
1. **Clear the phone number field**
2. **Enter one of these test numbers**:
   - `1234567890`
   - `9999999999` 
   - `9876543210`

3. **Click "Send OTP"** - Should work immediately
4. **Enter OTP**: `123456`
5. **Click "Verify"** - Should verify successfully

### Why your current number is failing:
- Real phone numbers are subject to Firebase SMS quotas
- Free Firebase plans have limited SMS sends per day
- Firebase may block repeated requests to the same number

### For Production Testing:
If you want to test with real numbers:
1. Check Firebase Console → Authentication → Settings → SMS quota
2. Make sure you're not hitting daily limits
3. Try a different phone number if the current one is rate-limited
4. Wait a few hours before retrying the same number

## Immediate Solution:
**Use test number `1234567890` with OTP `123456` for testing**