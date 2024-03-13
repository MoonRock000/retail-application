pending_status = ApprovalQueue.statuses[:pending]
1.upto(10) do |i|
  product = Product.new(
    product_name: "Book#{i}",
    price: i * 2000,
    status: ['active', 'inactive'].sample
  )

  if product.save
    if product.price > 5000
      ApprovalQueue.create(
        product: product,
        status: pending_status
      )
    else
      puts "Product '#{product.product_name}' created but not added to ApprovalQueue due to condition #{product.price} < 5000"
    end
  else
    puts "Failed to create product '#{product.product_name}': #{product.errors.full_messages.join(', ')}"
  end
end
