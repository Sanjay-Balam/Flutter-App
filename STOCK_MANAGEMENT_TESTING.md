# 🧪 Stock Management Testing Guide

## ✅ Complete Implementation Checklist

### Backend ✅
- [x] MenuItem schema with stock fields
- [x] StockHistory model
- [x] Stock API endpoints (update, history, low stock)
- [x] Auto-decrement on sale
- [x] Overselling prevention

### Frontend ✅
- [x] MenuItem model with stock fields
- [x] StockHistory model
- [x] Stock API service
- [x] Sell dialog with stock validation
- [x] Menu item cards with stock indicators
- [x] Stock Management Dialog
- [x] Stock History Screen
- [x] Integration with menu item card

---

## 📋 Testing Checklist

### 1. Backend API Testing

#### Create Menu Item with Stock
```bash
curl -X POST http://localhost:3000/business-sales-db/createresource/MenuItems \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Chocolate Cake",
    "categoryId": "YOUR_CATEGORY_ID",
    "prices": {"regular": 150},
    "description": "Delicious chocolate cake for testing",
    "stockQuantity": 50,
    "lowStockThreshold": 10,
    "trackStock": true,
    "isAvailable": true,
    "userId": "YOUR_USER_ID"
  }'
```

**Expected**: Success response with created item ID

#### Update Stock (Restock)
```bash
curl -X POST http://localhost:3000/business-sales-db/stock/update/MENU_ITEM_ID \
  -H "Content-Type: application/json" \
  -d '{
    "quantityChange": 100,
    "movementType": "RESTOCK",
    "userId": "YOUR_USER_ID",
    "reason": "Weekly restock"
  }'
```

**Expected**: 
- Success response
- Stock increases by 100
- History record created

#### Create Sale (Auto Stock Decrement)
```bash
curl -X POST http://localhost:3000/business-sales-db/createresource/SaleRecords \
  -H "Content-Type: application/json" \
  -d '{
    "menuItemId": "MENU_ITEM_ID",
    "itemName": "Test Chocolate Cake",
    "categoryId": "CATEGORY_ID",
    "categoryName": "Cakes",
    "size": "regular",
    "unitPrice": 150,
    "quantity": 5,
    "totalAmount": 750,
    "userId": "YOUR_USER_ID"
  }'
```

**Expected**:
- Sale created successfully
- Stock automatically decremented by 5
- Stock history shows SALE movement

#### Test Overselling Prevention
```bash
# Create sale with quantity > available stock
curl -X POST http://localhost:3000/business-sales-db/createresource/SaleRecords \
  -H "Content-Type: application/json" \
  -d '{
    "menuItemId": "MENU_ITEM_ID",
    "quantity": 999,
    ...
  }'
```

**Expected**: Error response "Insufficient stock"

#### Get Stock History
```bash
curl http://localhost:3000/business-sales-db/stock/history/MENU_ITEM_ID
```

**Expected**: Array of stock movements with all details

#### Get Low Stock Items
```bash
curl http://localhost:3000/business-sales-db/stock/low/YOUR_USER_ID
```

**Expected**: Array of items with stock ≤ threshold

---

### 2. Flutter App Testing

#### Initial Setup
1. ✅ Ensure backend is running
2. ✅ Have at least one category created
3. ✅ Have test user ID in AppConfig

#### Test Flow: Complete Stock Management

**Step 1: Create Menu Item with Stock**
1. Open app → Menu screen
2. Tap category
3. Tap "+ Add Item" button
4. Fill form:
   - Name: "Test Cake"
   - Price: 150
   - Category: Select any
5. Save item
6. **Note**: Initial stock will be 0

**Expected**: ✅ Item created, shows in list

---

**Step 2: Add Initial Stock**
1. Find your "Test Cake" item
2. Tap ⋮ (three dots) → "Manage Stock"
3. Stock Management Dialog opens
4. Configure:
   - Movement Type: "Restocked" (📥)
   - Quantity: 50
   - Reason: "Initial stock"
5. Tap "Update Stock"

**Expected**: 
- ✅ Success message shows
- ✅ Stock indicator appears on card
- ✅ Shows "Stock: 50"

---

**Step 3: View Stock History**
1. Tap ⋮ (three dots) → "Stock History"
2. Stock History Screen opens

**Expected**: 
- ✅ Shows "Current Stock: 50 units"
- ✅ Shows 1 history entry:
  - 📥 Restocked
  - +50 units
  - Reason: "Initial stock"

---

**Step 4: Sell Items (Stock Auto-Decrement)**
1. Go back to menu
2. Tap "Sell" button on "Test Cake"
3. Sell Dialog opens
4. Configure:
   - Quantity: 5
5. Tap "Sell"

**Expected**:
- ✅ Sale successful
- ✅ Stock indicator updates to "Stock: 45"
- ✅ Stock History shows:
  - 💰 Sale
  - -5 units
  - New stock: 45

---

**Step 5: Test Low Stock Warning**
1. Tap ⋮ → "Manage Stock"
2. Movement Type: "Damage/Expired"
3. Quantity: 40 (to bring stock to 5)
4. Reason: "Testing low stock"
5. Update

**Expected**:
- ✅ Stock indicator turns ORANGE
- ✅ Shows "⚠️ Low Stock (5)"
- ✅ Sell dialog shows orange warning

---

**Step 6: Test Out of Stock**
1. Sell remaining 5 items
2. Try to sell again

**Expected**:
- ✅ Stock indicator turns RED
- ✅ Shows "🔴 Out of Stock"
- ✅ "Sell" button disabled
- ✅ Sell dialog shows "Out of Stock" alert

---

**Step 7: Test Overselling Prevention**
1. Tap ⋮ → "Manage Stock"
2. Add 10 items back (Restock)
3. Tap "Sell"
4. Try to set quantity to 15
5. Try to tap [+] button beyond 10

**Expected**:
- ✅ [+] button disabled at quantity 10
- ✅ Sell button shows "Insufficient Stock"
- ✅ Cannot sell more than available

---

**Step 8: Test Different Movement Types**
Test each movement type:

**Restock (📥)**
- Adds to stock
- Used for new inventory

**Adjustment (⚙️)**
- Can add or remove
- Used for corrections

**Damage/Expired (❌)**
- Removes from stock
- Used for waste tracking

**Return (↩️)**
- Adds back to stock
- Used for customer returns

---

### 3. Edge Cases Testing

#### Test 1: Negative Stock Prevention
1. Manage Stock → Damage
2. Try to remove more than available
3. Preview shows negative

**Expected**: ⚠️ Warning "Cannot reduce stock below 0"

#### Test 2: Zero Quantity Validation
1. Manage Stock
2. Leave quantity empty or enter 0
3. Try to submit

**Expected**: ❌ Validation error "Quantity must be greater than 0"

#### Test 3: Concurrent Sales
1. Have stock: 10
2. Open sell dialog, set qty: 8
3. In another session, sell 5
4. Complete first sale

**Expected**: Backend prevents overselling, shows error

#### Test 4: Stock Tracking Disabled
1. Create item with `trackStock: false`
2. Try to sell

**Expected**: Can sell unlimited quantity (no stock check)

---

### 4. UI/UX Validation

**Stock Indicators**
- ✅ Green (check): Stock > threshold
- ✅ Orange (warning): Stock ≤ threshold
- ✅ Red (error): Stock = 0
- ✅ Icon + text clear and readable

**Sell Dialog**
- ✅ Stock status badge prominent
- ✅ Color coding matches status
- ✅ Quantity controls disabled appropriately
- ✅ Clear error messages

**Stock Management Dialog**
- ✅ Current stock clearly shown
- ✅ Movement type icons helpful
- ✅ Preview shows calculation
- ✅ Warnings visible for errors

**Stock History Screen**
- ✅ Timeline layout clear
- ✅ Icons represent movement types
- ✅ Date/time formatting good
- ✅ Quantity changes visible (+/-)

---

### 5. Performance Testing

**Load Test**
1. Create item with 1000 stock movements
2. Open Stock History

**Expected**: 
- ✅ Loads quickly (pagination)
- ✅ Smooth scrolling
- ✅ No lag

**Concurrent Users**
- Multiple users selling simultaneously
- Stock should remain accurate
- No race conditions

---

## 🐛 Known Issues / Limitations

### Current Limitations
1. **No Batch Operations**: Can't update multiple items at once
2. **No Stock Alerts**: No notifications for low stock
3. **No Forecasting**: No prediction of when stock will run out
4. **No Barcode Scanning**: Manual stock entry only

### Future Enhancements
- [ ] Low stock notifications
- [ ] Bulk stock import (CSV)
- [ ] Stock forecasting
- [ ] Barcode/QR scanning
- [ ] Stock transfers between locations
- [ ] Automated reorder points
- [ ] Stock valuation tracking

---

## 📊 Success Criteria

### Must Pass (Critical)
- [x] Stock decrements on sale
- [x] Cannot oversell (validation works)
- [x] Stock history accurate
- [x] Low stock warnings show
- [x] Out of stock prevention works

### Should Pass (Important)
- [x] All movement types work
- [x] Stock Management UI functional
- [x] Stock History displays correctly
- [x] Negative stock prevented
- [x] Real-time updates work

### Nice to Have (Enhancement)
- [ ] Performance optimized for 1000+ items
- [ ] Offline support
- [ ] Export stock reports
- [ ] Advanced filtering

---

## 🎯 Test Results Template

```
Date: ___________
Tester: ___________

Backend Tests:
[ ] Create item with stock - PASS/FAIL
[ ] Restock via API - PASS/FAIL
[ ] Sale auto-decrement - PASS/FAIL
[ ] Overselling prevention - PASS/FAIL
[ ] Stock history API - PASS/FAIL
[ ] Low stock query - PASS/FAIL

Frontend Tests:
[ ] Stock indicators display - PASS/FAIL
[ ] Sell dialog validation - PASS/FAIL
[ ] Stock management dialog - PASS/FAIL
[ ] Stock history screen - PASS/FAIL
[ ] Menu integration - PASS/FAIL

Edge Cases:
[ ] Negative stock prevention - PASS/FAIL
[ ] Zero quantity validation - PASS/FAIL
[ ] Concurrent sales - PASS/FAIL
[ ] Disabled tracking - PASS/FAIL

Notes:
_________________________________
_________________________________
```

---

## 🚀 Quick Start Test Script

```bash
#!/bin/bash
# Quick Stock Management Test

USER_ID="YOUR_USER_ID"
CATEGORY_ID="YOUR_CATEGORY_ID"
BASE_URL="http://localhost:3000/business-sales-db"

echo "1. Creating test item..."
ITEM=$(curl -s -X POST $BASE_URL/createresource/MenuItems \
  -H "Content-Type: application/json" \
  -d "{
    \"name\": \"Test Item\",
    \"categoryId\": \"$CATEGORY_ID\",
    \"prices\": {\"regular\": 100},
    \"stockQuantity\": 50,
    \"lowStockThreshold\": 10,
    \"trackStock\": true,
    \"userId\": \"$USER_ID\"
  }")

ITEM_ID=$(echo $ITEM | jq -r '.data._id')
echo "Created item: $ITEM_ID"

echo "\n2. Adding stock..."
curl -s -X POST $BASE_URL/stock/update/$ITEM_ID \
  -H "Content-Type: application/json" \
  -d "{
    \"quantityChange\": 100,
    \"movementType\": \"RESTOCK\",
    \"userId\": \"$USER_ID\",
    \"reason\": \"Test restock\"
  }" | jq '.'

echo "\n3. Creating sale..."
curl -s -X POST $BASE_URL/createresource/SaleRecords \
  -H "Content-Type: application/json" \
  -d "{
    \"menuItemId\": \"$ITEM_ID\",
    \"itemName\": \"Test Item\",
    \"categoryId\": \"$CATEGORY_ID\",
    \"categoryName\": \"Test\",
    \"size\": \"regular\",
    \"unitPrice\": 100,
    \"quantity\": 5,
    \"totalAmount\": 500,
    \"userId\": \"$USER_ID\"
  }" | jq '.'

echo "\n4. Getting stock history..."
curl -s $BASE_URL/stock/history/$ITEM_ID | jq '.'

echo "\nTest complete!"
```

---

**Last Updated**: October 10, 2025  
**Status**: Ready for Testing  
**Version**: 1.0

