# OTP Testing Guide

## Issues Fixed

### 1. **Test Phone Number Support Added**
- Added predefined test phone numbers that work without real SMS
- Test numbers: `+911234567890`, `+919999999999`, `+919876543210`
- Test OTP code for all test numbers: `123456`

### 2. **Improved OTP Verification Logic**
- Fixed the problematic sign-in/sign-out approach
- Now uses temporary anonymous user for verification
- Properly handles test numbers vs real numbers

### 3. **Better Error Handling**
- More specific error messages for different Firebase Auth errors
- Improved phone number validation
- Better debugging with detailed console logs

### 4. **Phone Number Validation**
- Validates Indian phone number format (+91 followed by 10 digits)
- Automatically formats phone numbers with +91 prefix
- Rejects invalid phone number formats

## How to Test

### Testing with Test Numbers (No SMS Required)
1. Use one of these test phone numbers:
   - `1234567890`
   - `9999999999` 
   - `9876543210`
2. Click "Send OTP" - should show success message immediately
3. Enter OTP code: `123456`
4. Click "Verify OTP" - should verify successfully

### Testing with Real Numbers (SMS Required)
1. Enter a real Indian mobile number (10 digits)
2. Click "Send OTP" - you should receive an SMS
3. Enter the 6-digit code from SMS
4. Click "Verify OTP" - should verify successfully

## Common Issues and Solutions

### "OTP can't be sent" Error
**Fixed**: Now supports test numbers that don't require SMS

### "Invalid phone number format" Error
**Solution**: 
- Use valid Indian mobile numbers (10 digits starting with 6-9)
- Or use the predefined test numbers

### SMS Not Received
**Solutions**:
1. Use test numbers for development: `+911234567890`, `+919999999999`, `+919876543210`
2. Check Firebase Console SMS quota (free tier has limits)
3. Verify your phone number is valid and can receive SMS
4. Wait up to 2 minutes for SMS delivery

### Verification Not Working
**Fixed**: Improved verification logic that doesn't interfere with user authentication

## Test Numbers and OTPs

| Phone Number | Formatted | OTP Code |
|-------------|-----------|----------|
| 1234567890  | +911234567890 | 123456 |
| 9999999999  | +919999999999 | 123456 |
| 9876543210  | +919876543210 | 123456 |

## Debug Information

Check the console logs for detailed debugging information:
- Phone number formatting
- OTP send success/failure
- Verification attempts
- Error codes and messages

## Firebase Console Settings

For production use with real phone numbers:
1. Enable Phone Authentication in Firebase Console
2. Add your app's SHA keys (Android)
3. Configure authorized domains (Web)
4. Monitor SMS quota usage

## Development vs Production

**Development (Test Numbers):**
- Use predefined test numbers
- No SMS costs
- Instant verification
- No rate limiting

**Production (Real Numbers):**
- Use real phone numbers
- SMS charges apply
- Actual SMS delivery
- Firebase rate limiting applies