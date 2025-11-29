import Foundation
import StoreKit

@objcMembers
class IAPManagerSwift: NSObject {
    
    var productIDs: [String] = ["com.erlendthune.polpriser"]
    var mvc: ETViewController?  // ETViewController will now be recognized here
    var purchaseInProgress: Bool = false
    var availableProducts: [Product] = []
    
    @objc static let sharedManager = IAPManagerSwift()
    
    private override init() {
        super.init()
        listenForTransactionUpdates() // Start listening for transaction updates
    }
    
    // This method is used to configure the manager with a view controller
    @objc func configure(with viewController: ETViewController) {
        self.mvc = viewController
    }
    
    @objc func fetchPrice(for productID: String, completion: @escaping (String?) -> Void) {
        Task {
            do {
                let products = try await Product.products(for: [productID])
                if let product = products.first {
                    // Use displayPrice for the localized price string
                    let formattedPrice = product.displayPrice
                    DispatchQueue.main.async {
                        completion(formattedPrice)
                    }
                    return
                }
                DispatchQueue.main.async {
                    completion(nil) // No product found
                }
            } catch {
                print("Failed to fetch product price: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    completion(nil)
                }
            }
        }
    }
    
    // Listen for transaction updates to avoid missing transactions
    private func listenForTransactionUpdates() {
        Task.detached { // Create a detached task to listen for transactions
            for await verificationResult in Transaction.updates {
                do {
                    _ = try self.verify(verificationResult)
                    // Handle the verified transaction
                    await self.processTransaction(verificationResult)
                } catch {
                    print("Transaction verification failed: \(error.localizedDescription)")
                    await self.mvc?.purchaseFailed(error.localizedDescription)

                }
            }
        }
    }
    
    // Verify a transaction
    private func verify(_ result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified(_, let error):
            throw error
        }
    }
    
    private func processTransaction(_ verificationResult: VerificationResult<Transaction>) async {
        switch verificationResult {
        case .unverified(let transaction, let error):
            // Handle the unverified transaction
            print("Unverified transaction: \(transaction.productID), Error: \(error.localizedDescription)")
            await mvc?.purchaseFailed(error.localizedDescription)
        case .verified(let transaction):
            // Handle the verified transaction
            switch transaction.revocationReason {
            case .none:
                print("Transaction completed for product: \(transaction.productID)")
                UserDefaults.standard.set(true, forKey: transaction.productID)
                UserDefaults.standard.synchronize()
                await mvc?.productPurchased()
            case .some:
                await mvc?.purchaseFailed("Transaksjonen er annulert")
                print("Transaction revoked: \(transaction.productID)")
            }

            // Finish the transaction
            await transaction.finish()
        }
    }

    // Fetch products from the App Store asynchronously
    @objc func fetchProducts() {
        Task {
            do {
                // Fetch products using StoreKit 2
                let products = try await Product.products(for: productIDs)
                
                for product in products {
                    print("Product: \(product.displayName), Price: \(product.displayPrice)")
                }
                
                self.availableProducts = products
                
                // If a purchase is in progress, attempt to purchase
                if purchaseInProgress {
                    purchaseProduct()
                }
                
            } catch {
                print("Failed to load products: \(error.localizedDescription)")
                // Handle error appropriately
            }
        }
    }
    
    @objc func purchaseProduct() {
        guard let productToBuy = availableProducts.first(where: { $0.id == "com.erlendthune.polpriser" }) else {
            fetchProducts()
            return
        }

        Task {
            do {
                let result = try await productToBuy.purchase()
                switch result {
                case .success(let verificationResult):
                    switch verificationResult {
                    case .verified(let transaction):
                        // Handle successful purchase
                        print("Purchase successful for product: \(transaction.productID)")
                        await transaction.finish()
                        UserDefaults.standard.set(true, forKey: transaction.productID)
                        UserDefaults.standard.synchronize()
                        await mvc?.productPurchased()
                    case .unverified(_, let error):
                        // Handle unverified transaction
                        print("Transaction unverified: \(error.localizedDescription)")
                        await mvc?.purchaseFailed("Transaction verification failed: \(error.localizedDescription)")
                    }
                case .userCancelled:
                    print("User cancelled the purchase.")
                    await mvc?.purchaseFailed("Purchase cancelled")
                case .pending:
                    print("Transaction is pending.")
                @unknown default:
                    print("Unknown result")
                }
            } catch {
                print("Purchase failed: \(error.localizedDescription)")
                await mvc?.purchaseFailed(error.localizedDescription)
            }
        }
    }

    @objc func restorePurchase() {
        Task {
            do {
                try await AppStore.sync()

                var foundEntitlements = false
                for await transaction in Transaction.currentEntitlements {
                    foundEntitlements = true
                    await processTransaction(transaction)
                }
                
                if !foundEntitlements {
                    await mvc?.purchaseFailed("Fant ingen kjøp som kunne gjenopprettes")
                }
            } catch let error as NSError {
                await mvc?.purchaseFailed(error.localizedDescription)
            }
        }
    }
}
