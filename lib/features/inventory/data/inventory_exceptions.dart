/// Thrown when [GET /api/erp/inventory-transfer-requests/{docEntry}] cannot return a document
/// (missing doc, server error payload, etc.). UI maps this to a friendly "not found" message.
class InventoryDocumentNotFoundException implements Exception {
  const InventoryDocumentNotFoundException();
}
