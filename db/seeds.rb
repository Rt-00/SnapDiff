# =============================================================================
# SnapDiff Development Seeds
# Run with: rails db:seed
# Idempotent — safe to run multiple times
# =============================================================================

puts "Seeding SnapDiff..."

# -----------------------------------------------------------------------------
# User
# -----------------------------------------------------------------------------
user = User.find_or_create_by!(email: "dev@snapdiff.local") do |u|
  u.password = "password123"
  u.password_confirmation = "password123"
end
puts "  User: #{user.email} (token: #{user.api_token})"

# -----------------------------------------------------------------------------
# Projects
# -----------------------------------------------------------------------------
ecommerce = Project.find_or_create_by!(name: "E-Commerce API", user: user) do |p|
  p.description = "Product catalog, cart and orders REST API"
end

payments = Project.find_or_create_by!(name: "Payments Service", user: user) do |p|
  p.description = "Stripe-based payment processing microservice"
end

puts "  Projects: #{Project.where(user: user).count}"

# -----------------------------------------------------------------------------
# Endpoints
# -----------------------------------------------------------------------------
ep_products  = Endpoint.find_or_create_by!(name: "List Products",    project: ecommerce) do |e|
  e.url         = "https://fakestoreapi.com/products"
  e.http_method = "GET"
end

ep_order     = Endpoint.find_or_create_by!(name: "Get Order #1042", project: ecommerce) do |e|
  e.url         = "https://fakestoreapi.com/orders/1042"
  e.http_method = "GET"
end

ep_user_me   = Endpoint.find_or_create_by!(name: "Current User Profile", project: ecommerce) do |e|
  e.url         = "https://fakestoreapi.com/users/me"
  e.http_method = "GET"
  e.headers     = { "Authorization" => "Bearer <token>" }
end

ep_payment   = Endpoint.find_or_create_by!(name: "Payment Intent", project: payments) do |e|
  e.url         = "https://api.payments-svc.example.com/v2/intents/pi_test"
  e.http_method = "GET"
  e.headers     = { "X-API-Key" => "sk_test_xxx" }
end

puts "  Endpoints: #{Endpoint.count}"

# =============================================================================
# Helper to create a snapshot without HTTP
# =============================================================================
def snap(endpoint, body, status: 200, ms: rand(80..320), triggered_by: "manual", name: nil, at: Time.current)
  endpoint.snapshots.create!(
    response_body:    body,
    status_code:      status,
    response_time_ms: ms,
    triggered_by:     triggered_by,
    taken_at:         at,
    name:             name
  )
end

# =============================================================================
# Snapshots — List Products (catalog drift)
# =============================================================================
puts "  Seeding snapshots for '#{ep_products.name}'..."

products_v1 = {
  "meta" => { "page" => 1, "per_page" => 20, "total" => 3, "total_pages" => 1 },
  "data" => [
    {
      "id" => 101,
      "sku" => "TSHIRT-BLK-M",
      "name" => "Classic Black T-Shirt",
      "slug" => "classic-black-t-shirt",
      "category" => { "id" => 5, "name" => "Apparel", "path" => "apparel/t-shirts" },
      "price" => { "amount" => 2999, "currency" => "USD", "formatted" => "$29.99" },
      "stock" => { "available" => true, "quantity" => 142, "reserved" => 8 },
      "images" => [
        { "url" => "https://cdn.example.com/products/101/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "black", "size" => "M", "weight_g" => 200 },
      "rating" => { "average" => 4.7, "count" => 312 },
      "tags" => [ "bestseller", "cotton", "unisex" ],
      "created_at" => "2024-01-15T10:00:00Z",
      "updated_at" => "2025-11-20T08:30:00Z"
    },
    {
      "id" => 102,
      "sku" => "HOODIE-GRY-L",
      "name" => "Grey Pullover Hoodie",
      "slug" => "grey-pullover-hoodie",
      "category" => { "id" => 5, "name" => "Apparel", "path" => "apparel/hoodies" },
      "price" => { "amount" => 5499, "currency" => "USD", "formatted" => "$54.99" },
      "stock" => { "available" => true, "quantity" => 54, "reserved" => 2 },
      "images" => [
        { "url" => "https://cdn.example.com/products/102/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 },
        { "url" => "https://cdn.example.com/products/102/back.jpg",  "alt" => "Back view",  "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "grey", "size" => "L", "weight_g" => 450, "material" => "80% cotton, 20% polyester" },
      "rating" => { "average" => 4.5, "count" => 89 },
      "tags" => [ "cotton", "winter" ],
      "created_at" => "2024-03-01T12:00:00Z",
      "updated_at" => "2025-09-10T14:00:00Z"
    },
    {
      "id" => 103,
      "sku" => "CAP-RED-OS",
      "name" => "Red Snapback Cap",
      "slug" => "red-snapback-cap",
      "category" => { "id" => 7, "name" => "Accessories", "path" => "accessories/caps" },
      "price" => { "amount" => 1999, "currency" => "USD", "formatted" => "$19.99" },
      "stock" => { "available" => true, "quantity" => 200, "reserved" => 0 },
      "images" => [
        { "url" => "https://cdn.example.com/products/103/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "red", "size" => "one-size", "adjustable" => true },
      "rating" => { "average" => 4.2, "count" => 47 },
      "tags" => [ "cap", "streetwear" ],
      "created_at" => "2024-06-20T09:00:00Z",
      "updated_at" => "2025-06-01T11:00:00Z"
    }
  ]
}

# Snapshot V2 — price increase, stock drop, new product, removed tag, new field
products_v2 = {
  "meta" => { "page" => 1, "per_page" => 20, "total" => 4, "total_pages" => 1, "api_version" => "2.1" },
  "data" => [
    {
      "id" => 101,
      "sku" => "TSHIRT-BLK-M",
      "name" => "Classic Black T-Shirt",
      "slug" => "classic-black-t-shirt",
      "category" => { "id" => 5, "name" => "Apparel", "path" => "apparel/t-shirts" },
      "price" => { "amount" => 3499, "currency" => "USD", "formatted" => "$34.99", "original_amount" => 2999, "on_sale" => false },
      "stock" => { "available" => true, "quantity" => 87, "reserved" => 12 },
      "images" => [
        { "url" => "https://cdn.example.com/products/101/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "black", "size" => "M", "weight_g" => 200 },
      "rating" => { "average" => 4.8, "count" => 401 },
      "tags" => [ "bestseller", "cotton", "unisex", "new-price" ],
      "seo" => { "title" => "Classic Black T-Shirt | SnapMerch", "description" => "Premium cotton tee." },
      "created_at" => "2024-01-15T10:00:00Z",
      "updated_at" => "2026-03-20T08:30:00Z"
    },
    {
      "id" => 102,
      "sku" => "HOODIE-GRY-L",
      "name" => "Grey Pullover Hoodie",
      "slug" => "grey-pullover-hoodie",
      "category" => { "id" => 5, "name" => "Apparel", "path" => "apparel/hoodies" },
      "price" => { "amount" => 5499, "currency" => "USD", "formatted" => "$54.99" },
      "stock" => { "available" => false, "quantity" => 0, "reserved" => 0 },
      "images" => [
        { "url" => "https://cdn.example.com/products/102/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 },
        { "url" => "https://cdn.example.com/products/102/back.jpg",  "alt" => "Back view",  "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "grey", "size" => "L", "weight_g" => 450, "material" => "80% cotton, 20% polyester" },
      "rating" => { "average" => 4.5, "count" => 91 },
      "tags" => [ "cotton", "winter" ],
      "created_at" => "2024-03-01T12:00:00Z",
      "updated_at" => "2026-03-22T14:00:00Z"
    },
    {
      "id" => 104,
      "sku" => "JOGGER-NVY-M",
      "name" => "Navy Jogger Pants",
      "slug" => "navy-jogger-pants",
      "category" => { "id" => 5, "name" => "Apparel", "path" => "apparel/bottoms" },
      "price" => { "amount" => 4499, "currency" => "USD", "formatted" => "$44.99" },
      "stock" => { "available" => true, "quantity" => 75, "reserved" => 3 },
      "images" => [
        { "url" => "https://cdn.example.com/products/104/main.jpg", "alt" => "Front view", "width" => 800, "height" => 800 }
      ],
      "attributes" => { "color" => "navy", "size" => "M", "weight_g" => 380, "material" => "French Terry" },
      "rating" => { "average" => 0.0, "count" => 0 },
      "tags" => [ "new", "jogger", "cotton" ],
      "created_at" => "2026-03-24T00:00:00Z",
      "updated_at" => "2026-03-24T00:00:00Z"
    }
  ]
}

s_products_v1 = snap(ep_products, products_v1,
  ms: 124, name: "Before price update (v1)", at: 3.days.ago)

s_products_v2 = snap(ep_products, products_v2,
  ms: 138, name: "After price update + new SKU (v2)", at: 1.hour.ago)

ep_products.update!(baseline_snapshot: s_products_v1)

# =============================================================================
# Snapshots — Get Order (order lifecycle drift)
# =============================================================================
puts "  Seeding snapshots for '#{ep_order.name}'..."

order_placed = {
  "order_id" => "ORD-1042",
  "status" => "placed",
  "placed_at" => "2026-03-20T14:22:00Z",
  "customer" => {
    "id" => "USR-88",
    "name" => "Alice Ferreira",
    "email" => "alice@example.com",
    "address" => {
      "line1" => "Rua das Flores, 42",
      "city" => "São Paulo",
      "state" => "SP",
      "postal_code" => "01310-100",
      "country" => "BR"
    }
  },
  "items" => [
    { "sku" => "TSHIRT-BLK-M", "name" => "Classic Black T-Shirt", "qty" => 2, "unit_price" => 2999, "subtotal" => 5998 },
    { "sku" => "CAP-RED-OS",   "name" => "Red Snapback Cap",       "qty" => 1, "unit_price" => 1999, "subtotal" => 1999 }
  ],
  "pricing" => {
    "subtotal" => 7997,
    "discount" => 0,
    "shipping" => 1500,
    "tax" => 1439,
    "total" => 10936,
    "currency" => "BRL"
  },
  "payment" => {
    "method" => "credit_card",
    "status" => "pending",
    "last4" => "4242",
    "brand" => "visa"
  },
  "fulfillment" => nil,
  "timeline" => [
    { "event" => "order_placed", "at" => "2026-03-20T14:22:00Z" }
  ]
}

order_shipped = {
  "order_id" => "ORD-1042",
  "status" => "shipped",
  "placed_at" => "2026-03-20T14:22:00Z",
  "shipped_at" => "2026-03-22T09:15:00Z",
  "estimated_delivery" => "2026-03-25T23:59:00Z",
  "customer" => {
    "id" => "USR-88",
    "name" => "Alice Ferreira",
    "email" => "alice@example.com",
    "address" => {
      "line1" => "Rua das Flores, 42",
      "city" => "São Paulo",
      "state" => "SP",
      "postal_code" => "01310-100",
      "country" => "BR"
    }
  },
  "items" => [
    { "sku" => "TSHIRT-BLK-M", "name" => "Classic Black T-Shirt", "qty" => 2, "unit_price" => 2999, "subtotal" => 5998 },
    { "sku" => "CAP-RED-OS",   "name" => "Red Snapback Cap",       "qty" => 1, "unit_price" => 1999, "subtotal" => 1999 }
  ],
  "pricing" => {
    "subtotal" => 7997,
    "discount" => 800,
    "discount_code" => "SPRING10",
    "shipping" => 0,
    "tax" => 1295,
    "total" => 9492,
    "currency" => "BRL"
  },
  "payment" => {
    "method" => "credit_card",
    "status" => "captured",
    "last4" => "4242",
    "brand" => "visa",
    "captured_at" => "2026-03-20T14:25:00Z"
  },
  "fulfillment" => {
    "carrier" => "Correios",
    "tracking_code" => "BR123456789BR",
    "tracking_url" => "https://rastreamento.correios.com.br/BR123456789BR",
    "warehouse" => "SP-01",
    "weight_g" => 650
  },
  "timeline" => [
    { "event" => "order_placed",    "at" => "2026-03-20T14:22:00Z" },
    { "event" => "payment_captured", "at" => "2026-03-20T14:25:00Z" },
    { "event" => "order_packed",    "at" => "2026-03-21T18:00:00Z" },
    { "event" => "shipped",         "at" => "2026-03-22T09:15:00Z" }
  ]
}

s_order_placed  = snap(ep_order, order_placed,  ms: 88,  name: "Order placed",  at: 4.days.ago)
s_order_shipped = snap(ep_order, order_shipped, ms: 95,  name: "Order shipped", at: 2.days.ago)
ep_order.update!(baseline_snapshot: s_order_placed)

# =============================================================================
# Snapshots — User Profile (field rename + new nested object)
# =============================================================================
puts "  Seeding snapshots for '#{ep_user_me.name}'..."

profile_v1 = {
  "id" => "USR-88",
  "username" => "alice_f",
  "full_name" => "Alice Ferreira",
  "email" => "alice@example.com",
  "avatar_url" => "https://cdn.example.com/avatars/usr88.jpg",
  "role" => "customer",
  "verified" => false,
  "created_at" => "2023-08-10T00:00:00Z",
  "preferences" => {
    "language" => "pt-BR",
    "currency" => "BRL",
    "notifications" => { "email" => true, "sms" => false, "push" => true }
  },
  "stats" => { "orders_total" => 3, "reviews_total" => 1, "wishlist_count" => 12 }
}

profile_v2 = {
  "id" => "USR-88",
  "username" => "alice_f",
  "display_name" => "Alice Ferreira",
  "email" => "alice@example.com",
  "avatar_url" => "https://cdn.example.com/avatars/usr88_v2.jpg",
  "role" => "customer",
  "verified" => true,
  "verified_at" => "2026-03-01T10:00:00Z",
  "created_at" => "2023-08-10T00:00:00Z",
  "tier" => { "name" => "Gold", "points" => 1420, "next_tier" => "Platinum", "points_needed" => 580 },
  "preferences" => {
    "language" => "pt-BR",
    "currency" => "BRL",
    "notifications" => { "email" => true, "sms" => true, "push" => true, "marketing" => false }
  },
  "stats" => { "orders_total" => 5, "reviews_total" => 2, "wishlist_count" => 14, "loyalty_points" => 1420 }
}

s_profile_v1 = snap(ep_user_me, profile_v1, ms: 61, name: "Pre-verification",  at: 30.days.ago)
s_profile_v2 = snap(ep_user_me, profile_v2, ms: 58, name: "Post-verification + loyalty tier", at: 1.day.ago)
ep_user_me.update!(baseline_snapshot: s_profile_v1)

# =============================================================================
# Snapshots — Payment Intent (breaking change simulation)
# =============================================================================
puts "  Seeding snapshots for '#{ep_payment.name}'..."

payment_v1 = {
  "id" => "pi_3OxKtest",
  "object" => "payment_intent",
  "amount" => 10936,
  "currency" => "brl",
  "status" => "requires_payment_method",
  "client_secret" => "pi_3OxKtest_secret_xxx",
  "payment_method_types" => [ "card" ],
  "metadata" => { "order_id" => "ORD-1042", "user_id" => "USR-88" },
  "created" => 1742479320,
  "livemode" => false,
  "last_payment_error" => nil,
  "charges" => { "object" => "list", "data" => [], "has_more" => false, "total_count" => 0 }
}

payment_v2 = {
  "id" => "pi_3OxKtest",
  "object" => "payment_intent",
  "amount" => 9492,
  "amount_received" => 9492,
  "currency" => "brl",
  "status" => "succeeded",
  "payment_method" => "pm_card_visa",
  "payment_method_types" => [ "card", "pix" ],
  "metadata" => { "order_id" => "ORD-1042", "user_id" => "USR-88", "discount_code" => "SPRING10" },
  "created" => 1742479320,
  "livemode" => false,
  "last_payment_error" => nil,
  "next_action" => nil,
  "charges" => {
    "object" => "list",
    "has_more" => false,
    "total_count" => 1,
    "data" => [
      {
        "id" => "ch_3OxKtest",
        "amount" => 9492,
        "captured" => true,
        "paid" => true,
        "receipt_url" => "https://pay.stripe.com/receipts/ch_3OxKtest",
        "created" => 1742479500
      }
    ]
  }
}

payment_v3_error = {
  "error" => {
    "type" => "invalid_request_error",
    "code" => "resource_missing",
    "message" => "No such payment_intent: 'pi_3OxKtest'",
    "param" => "id",
    "doc_url" => "https://stripe.com/docs/error-codes/resource-missing"
  }
}

s_pay_v1     = snap(ep_payment, payment_v1,      ms: 203, name: "Intent created",   at: 5.days.ago)
s_pay_v2     = snap(ep_payment, payment_v2,      ms: 190, name: "Payment succeeded", at: 4.days.ago)
s_pay_v3_err = snap(ep_payment, payment_v3_error, status: 404, ms: 45, name: "404 — Intent not found", at: 2.hours.ago)
ep_payment.update!(baseline_snapshot: s_pay_v1)

# =============================================================================
# Diff Reports (pre-generated so comparison page works immediately)
# =============================================================================
puts "  Generating diff reports..."

[
  [ s_products_v1,  s_products_v2,  "Products: price + stock + new SKU" ],
  [ s_order_placed, s_order_shipped, "Order: placed → shipped" ],
  [ s_profile_v1,   s_profile_v2,   "Profile: verification + loyalty tier" ],
  [ s_pay_v1,       s_pay_v2,       "Payment: requires_payment_method → succeeded" ],
  [ s_pay_v2,       s_pay_v3_err,   "Payment: succeeded → 404 error" ]
].each do |snap_a, snap_b, label|
  service   = Snapshots::DiffService.new(snap_b)
  diff_data = service.send(:compute_diff, snap_a.response_body, snap_b.response_body)
  summary   = service.send(:summarize, diff_data)

  DiffReport.find_or_create_by!(snapshot_a: snap_a, snapshot_b: snap_b) do |r|
    r.diff_data = diff_data
    r.summary   = summary
  end
  puts "    ✓ #{label} (#{summary})"
end

puts ""
puts "Done! Login: dev@snapdiff.local / password123"
