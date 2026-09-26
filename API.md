# MSL Stock Check — API Reference

## Base URLs

| Environment | URL |
|---|---|
| Production (Cloudflare Tunnel) | `https://msl.rawabimarket.com/api` |
| Local | `http://127.0.0.1:5023/api` |
| Uploaded images | `https://msl.rawabimarket.com/uploads/<file>` |
| Health check | `GET https://msl.rawabimarket.com/api/health` |

## Authentication

Every endpoint except `POST /api/auth/login` and `GET /api/health` needs a JWT header. Tokens expire after 12 hours.

```
Authorization: Bearer <token>
```

Roles: `admin`, `supervisor`. "Any" means any logged-in user.

---

## Call Methods (GET — read data)

| Endpoint | Role | Query / Params | Description |
|---|---|---|---|
| `GET /api/health` | Public | – | Service status |
| `GET /api/branches` | Any | – | List branches |
| `GET /api/branches/groups` | Any | – | List branch groups |
| `GET /api/branches/bootstrap` | Any | – | Branches and groups in one call |
| `GET /api/products` | Any | `branchId`, `search`, `mslOnly=1`, `page`, `limit`, `sortBy`, `brand` | Product list for a branch |
| `GET /api/products/bootstrap` | Any | `branchId`, `limit` (default 25), `sortBy` | Initial stock-check page data |
| `GET /api/products/brands` | Any | – | List product brands |
| `GET /api/products/matrix` | Admin | – | Product × branch matrix |
| `GET /api/products/template/bulk` | Admin | – | Download the bulk-upload Excel template |
| `GET /api/stock/check/:productId/:branchId/images` | Any | – | Images for a stock check |
| `GET /api/stock/check/:productId/:branchId/detail` | Any | – | Stock-check detail (remarks, ERP stock) |
| `GET /api/stock/branch/:branchId/summary` | Any | – | Branch stock summary |
| `GET /api/dashboard/summary` | Admin | – | Dashboard summary |
| `GET /api/dashboard/updates` | Admin | `date` or `dateFrom`+`dateTo`, `groupId`, `outletId`, `brand` | Stock updates list |
| `GET /api/export/updates` | Admin | `format` (`xlsx`), `dateFrom`, `dateTo`, `groupId`, `outletId`, `brand` | Export the updates report |
| `GET /api/export/mt-msl` | Admin | – | Export the MT MSL report |
| `GET /api/export/stock-status` | Admin | – | Export the stock status report |
| `GET /api/export/branch/:branchId` | Admin, Supervisor | – | Export one branch's report |

---

## Push Methods (POST / PUT / DELETE — write data)

### `POST /api/auth/login` — Public

```json
{ "username": "string", "password": "string" }
```

Response: `{ "token": "...", "user": { "id", "username", "role", "branchId", "branchName" } }`

### `PUT /api/stock/check` — Supervisor, Admin

Creates or updates a stock check.

```json
{
  "product_id": 1,
  "branch_id": 2,
  "is_available": true,
  "remarks": "optional",
  "ebt_stock": {
    "store_code": "string",
    "total_stock": 0,
    "location_stock": 0,
    "back_store_stock": 0,
    "uom": "string",
    "item_no": "string",
    "ebt_found": true
  }
}
```

`ebt_stock` is optional. Response: `{ "id": <checkId>, "success": true }`

### `POST /api/stock/check/:checkId/image` — Supervisor, Admin

`multipart/form-data` (max 10 MB). Use `checkId = 0` to create the stock check automatically.

| Field | Type |
|---|---|
| `image` | file |
| `product_id` | number |
| `branch_id` | number |
| `remarks` | string (optional) |

### `PUT /api/stock/check/:productId/:branchId/read` — Admin

Marks remarks as read. No body.

### `POST /api/products` — Admin

```json
{ "sl_no": 1, "barcode": "string", "item_name": "string", "brand": "string", "branch_ids": [1, 2] }
```

### `PUT /api/products/:id` — Admin

Same body as `POST /api/products`. Replaces the product's branch assignments and keeps each branch's existing visibility setting.

### `PUT /api/products/:productId/branches/:branchId/visibility` — Admin

```json
{ "is_visible": true }
```

### `DELETE /api/products/:id` — Admin

Soft delete (sets `is_active = 0`).

### `POST /api/products/bulk` — Admin

`multipart/form-data` with field `file` (Excel `.xlsx`). Columns: SL No, Barcode, Item Name, Brand, then one column per branch group (`✓`, `Y`, or `1` assigns the product). Response: `{ "imported": <count> }`

### `DELETE /api/dashboard/updates` — Admin

Clears stock updates. Query: `all=1`, or `date`, or `dateFrom`+`dateTo`, plus optional `groupId`, `outletId`, `brand`.
