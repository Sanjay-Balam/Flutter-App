# Multi-Item Transaction & Invoice System

## Overview

The application now supports **multi-item transactions** with a shopping cart system, allowing users to:
- Add multiple items to a cart
- Checkout all items in a single transaction
- Generate a single invoice for multiple items
- View, share, and print comprehensive multi-item invoices

This upgrade addresses the limitation of the previous single-item sale system.

---

## Architecture

### Backend Components

#### 1. **Transaction Model** (`Transaction.ts`)
- **Location**: `business-sales-backend/src/models/Transaction.ts`
- **Features**:
  - Stores multiple `TransactionItem` objects
  - Automatically calculates totals (subtotal, tax, grand total)
  - Tracks invoice generation status
  - Supports payment methods and status
  - Includes timestamps and notes

**Schema Structure**:
```typescript
Transaction {
  userId: ObjectId
  items: [TransactionItem]  // Array of items
  totalAmount: Number       // Sum of all subtotals
  taxAmount: Number
  grandTotal: Number
  timestamp: Date
  notes: String
  invoiceNumber: String
  invoiceGenerated: Boolean
  invoiceGeneratedAt: Date
  paymentMethod: String     // 'cash', 'card', 'upi', 'other'
  paymentStatus: String     // 'pending', 'paid', 'partially_paid', 'refunded'
}

TransactionItem {
  menuItemId: ObjectId
  itemName: String
  categoryId: ObjectId
  categoryName: String
  size: String              // 'small', 'regular', 'large'
  unitPrice: Number
  quantity: Number
  subtotal: Number          // unitPrice * quantity
}
```

#### 2. **Transaction Service** (`TransactionService.ts`)
- **Location**: `business-sales-backend/src/services/TransactionService.ts`
- **Methods**:
  - `createTransaction()` - Create a new multi-item transaction
  - `generateInvoiceForTransaction()` - Generate invoice for a transaction
  - `getTransactionInvoiceData()` - Retrieve invoice data
  - `getUserTransactions()` - Get all transactions for a user
  - `getUserTransactionInvoices()` - Get all invoiced transactions

#### 3. **Transaction Routes** (`transaction.routes.ts`)
- **Location**: `business-sales-backend/src/routes/transaction.routes.ts`
- **Endpoints**:

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/:database/transactions` | Create a new transaction |
| `GET` | `/:database/transactions/:transactionId` | Get transaction by ID |
| `GET` | `/:database/transactions/user/:userId` | Get all user transactions |
| `POST` | `/:database/transactions/:transactionId/generate-invoice` | Generate invoice |
| `GET` | `/:database/transactions/:transactionId/invoice` | Get invoice data |
| `GET` | `/:database/transaction-invoices/:userId` | Get all user invoices |

---

### Frontend Components

#### 1. **Models**

##### `Transaction` & `TransactionItem`
- **Location**: `flutter_app/lib/models/transaction.dart`
- Mirrors backend structure
- Includes helper methods for date filtering
- Provides computed properties (`totalItems`, `uniqueItems`)

##### `TransactionInvoice`
- **Location**: `flutter_app/lib/models/transaction_invoice.dart`
- Combines transaction data with business details and invoice settings
- Used for invoice generation and display

#### 2. **Cart System**

##### Cart Provider (`cart_provider.dart`)
- **Location**: `flutter_app/lib/providers/cart_provider.dart`
- **Features**:
  - Add items to cart (combines duplicates by incrementing quantity)
  - Update item quantities
  - Remove items
  - Clear cart
  - Calculate totals

**Key Providers**:
```dart
cartProvider                // List<CartItem>
cartTotalProvider          // double - total amount
cartItemCountProvider      // int - total quantity
cartUniqueItemsProvider    // int - unique items count
isCartEmptyProvider        // bool - cart empty status
```

##### Cart Button Widget (`cart_button.dart`)
- **Location**: `flutter_app/lib/widgets/cart_button.dart`
- Displays cart icon with item count badge
- Navigates to cart screen

#### 3. **Shopping Experience**

##### Updated Menu Screen
- **Location**: `flutter_app/lib/screens/menu_screen.dart`
- **Features**:
  - Cart button in app bar
  - Two selling options when clicking "Sell":
    1. **Sell Immediately** - Direct sale with invoice (legacy behavior)
    2. **Add to Cart** - Add to cart and continue shopping

##### Cart Screen (`cart_screen.dart`)
- **Location**: `flutter_app/lib/screens/cart_screen.dart`
- **Features**:
  - View all cart items
  - Adjust quantities (+ / - buttons)
  - Add transaction notes
  - See total amount
  - Checkout to create transaction and generate invoice
  - Clear cart option

#### 4. **Invoice System**

##### Transaction API Service (`transaction_api_service.dart`)
- **Location**: `flutter_app/lib/services/transaction_api_service.dart`
- **Methods**:
  - `createTransaction()` - Submit cart to backend
  - `generateInvoice()` - Generate invoice for transaction
  - `getInvoiceData()` - Retrieve invoice
  - `getUserTransactions()` - Get user's transactions
  - `generateTransactionInvoicePDF()` - Create PDF with multiple items
  - `shareInvoice()` - Share PDF via system share sheet
  - `printInvoice()` - Print invoice

**PDF Features**:
- Displays all items in a table format
- Shows individual item details (name, size, quantity, rate, amount)
- Calculates and displays subtotal, tax, and grand total
- Includes transaction summary (total items, unique items, payment method)
- Shows transaction notes if provided

##### Transaction Invoice Dialog (`transaction_invoice_dialog.dart`)
- **Location**: `flutter_app/lib/widgets/transaction_invoice_dialog.dart`
- **Features**:
  - Beautiful invoice display
  - Item-by-item breakdown
  - Summary cards (Total Items, Unique Items)
  - Share and Print buttons
  - Date/time display
  - Notes section

---

## Usage Flow

### For Users

#### Option 1: Single Item Sale (Legacy - Still Supported)
1. Navigate to Menu
2. Click "Sell" on any item
3. Choose "Sell Immediately"
4. Select size and quantity
5. Click "Sell" → Invoice generated instantly

#### Option 2: Multi-Item Cart (New Feature)
1. Navigate to Menu
2. Click "Sell" on first item
3. Choose "Add to Cart"
4. Select size and quantity
5. Click "Sell" → Item added to cart
6. Repeat steps 2-5 for more items
7. Click cart icon (shows item count badge)
8. Review items in cart
9. Adjust quantities if needed
10. Add transaction notes (optional)
11. Click "Checkout"
12. Transaction created & invoice generated
13. View/Share/Print invoice

### API Examples

#### Create Multi-Item Transaction
```bash
POST /DemoDB/transactions
Content-Type: application/json

{
  "userId": "688722a1574e0612934de3a0",
  "items": [
    {
      "menuItemId": "68e4eab01e3f4e83f60d9c16",
      "itemName": "Cow Milk",
      "categoryId": "68e4ea051e3f4e83f60d9c02",
      "categoryName": "Milk Cakes",
      "size": "regular",
      "unitPrice": 99,
      "quantity": 2,
      "subtotal": 198
    },
    {
      "menuItemId": "68e4eab11e3f4e83f60d9c1d",
      "itemName": "Chocolate Brownie",
      "categoryId": "68e4ea101e3f4e83f60d9c0b",
      "categoryName": "Chocolate Brownie",
      "size": "small",
      "unitPrice": 80,
      "quantity": 3,
      "subtotal": 240
    }
  ],
  "notes": "Customer order - table 5",
  "paymentMethod": "cash",
  "paymentStatus": "paid"
}

Response:
{
  "success": true,
  "data": {
    "_id": "68f21243c14efafdf66740dc",
    "userId": "688722a1574e0612934de3a0",
    "items": [...],
    "totalAmount": 438,
    "grandTotal": 438,
    "invoiceGenerated": false,
    ...
  }
}
```

#### Generate Invoice
```bash
POST /DemoDB/transactions/68f21243c14efafdf66740dc/generate-invoice
Content-Type: application/json

{
  "userId": "688722a1574e0612934de3a0"
}

Response:
{
  "success": true,
  "data": {
    "invoiceNumber": "INV-0005",
    "transaction": {...},
    "businessDetails": {...},
    "invoiceSettings": {...},
    "generatedAt": "2025-10-17T09:52:41.975Z"
  }
}
```

---

## Benefits

### Business Advantages
✅ **Faster Service** - Add multiple items before checkout  
✅ **Better Organization** - One invoice per customer order  
✅ **Professional Invoices** - Detailed multi-item invoices  
✅ **Reduced Mistakes** - Review cart before finalizing  
✅ **Better Record Keeping** - Transactions grouped logically  

### Technical Advantages
✅ **Scalable Architecture** - Separate concerns (Transaction vs SaleRecord)  
✅ **Backward Compatible** - Old single-item sales still work  
✅ **Type Safe** - Full TypeScript and Dart type definitions  
✅ **RESTful API** - Clean, documented endpoints  
✅ **Comprehensive PDF** - Professional multi-item invoices  

---

## Database Schema

### Transactions Collection
```javascript
{
  "_id": ObjectId("68f21243c14efafdf66740dc"),
  "userId": ObjectId("688722a1574e0612934de3a0"),
  "items": [
    {
      "menuItemId": ObjectId("68e4eab01e3f4e83f60d9c16"),
      "itemName": "Cow Milk",
      "categoryId": ObjectId("68e4ea051e3f4e83f60d9c02"),
      "categoryName": "Milk Cakes",
      "size": "regular",
      "unitPrice": 99,
      "quantity": 2,
      "subtotal": 198
    },
    {
      "menuItemId": ObjectId("68e4eab11e3f4e83f60d9c1d"),
      "itemName": "Chocolate Brownie",
      "categoryId": ObjectId("68e4ea101e3f4e83f60d9c0b"),
      "categoryName": "Chocolate Brownie",
      "size": "small",
      "unitPrice": 80,
      "quantity": 3,
      "subtotal": 240
    }
  ],
  "totalAmount": 438,
  "taxAmount": 0,
  "grandTotal": 438,
  "timestamp": ISODate("2025-10-17T09:52:41.975Z"),
  "notes": "Customer order - table 5",
  "invoiceNumber": "INV-0005",
  "invoiceGenerated": true,
  "invoiceGeneratedAt": ISODate("2025-10-17T09:53:15.123Z"),
  "paymentMethod": "cash",
  "paymentStatus": "paid",
  "createdAt": ISODate("2025-10-17T09:52:41.975Z"),
  "updatedAt": ISODate("2025-10-17T09:53:15.123Z")
}
```

---

## Migration Notes

### No Breaking Changes
- The existing `SaleRecords` collection remains unchanged
- Single-item sales continue to work as before
- New `Transactions` collection coexists with `SaleRecords`
- Both systems can be used simultaneously

### Future Considerations
- Analytics could aggregate both `SaleRecords` and `Transactions`
- Stock management works with both systems
- Invoice numbering is shared across both systems

---

## Testing

### Backend Tests Performed
✅ Create multi-item transaction (2+ items)  
✅ Generate invoice for transaction  
✅ Retrieve transaction invoice data  
✅ List user transactions  
✅ Dynamic database name support  

### Frontend Features to Test
🔲 Add items to cart from menu  
🔲 Update cart item quantities  
🔲 Remove cart items  
🔲 Checkout flow  
🔲 View transaction invoice  
🔲 Share invoice PDF  
🔲 Print invoice  

---

## Files Changed/Added

### Backend
**New Files:**
- `src/models/Transaction.ts`
- `src/services/TransactionService.ts`
- `src/routes/transaction.routes.ts`

**Modified Files:**
- `src/services/SearchService.ts` (added Transaction to modelMap)
- `index.ts` (registered transaction routes)

### Frontend
**New Files:**
- `lib/models/transaction.dart`
- `lib/models/transaction_invoice.dart`
- `lib/providers/cart_provider.dart`
- `lib/services/transaction_api_service.dart`
- `lib/widgets/cart_button.dart`
- `lib/screens/cart_screen.dart`
- `lib/widgets/transaction_invoice_dialog.dart`

**Modified Files:**
- `lib/screens/menu_screen.dart` (added cart button and cart options)
- `pubspec.yaml` (JSON serialization code generation)

---

## API Documentation

Full API documentation available at:
- **Swagger UI**: http://localhost:3000/swagger
- **Tag**: "Transactions"

---

## Conclusion

This multi-item transaction system provides a complete, production-ready shopping cart and invoicing solution. It maintains backward compatibility while offering a modern, professional user experience for handling complex multi-item orders.

**Key Achievement**: Users can now sell multiple items at once and generate a single comprehensive invoice! 🎉

