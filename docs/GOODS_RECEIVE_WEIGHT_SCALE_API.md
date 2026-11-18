# Goods Receive Weight Scale API

Flutter calls these authenticated endpoints through `GoodsReceiveRepository`
under the configured `WM3_API_Mobile` IIS application.

| Endpoint | Purpose | Stored procedure |
| --- | --- | --- |
| GET api/GoodsReceiveWeightScale/Setup | Resolve Packing Line, scale and printer; return KCF SKU, packaging and latest Batch | Direct master-table query |
| GET Mobile/GoodsReceiveWeightScale/Weight | Read the latest stable weight for a scale | TBD |
| POST api/GoodsReceiveWeightScale/Receive | Save receipt and generate bag number; Flutter calls Print API only after this succeeds | `usp_blind_receipt_weight_scale_update_qty` |
| POST api/GoodsReceiveWeightScale/CloseLatestOrder | Close the current/latest open receipt order for the tablet's scale mapping and Packing Line | `usp_close_inbound_order_weight_scale` |
| GET Mobile/GoodsReceiveWeightScale/Labels | Search label-print history for Reprint Label | TBD |
| POST Mobile/GoodsReceiveWeightScale/Reprint | Queue selected labels for the mapped printer | TBD |

All responses use `message_code`, `is_success`, `message`, and `data`.
The Android client sends `X-Client-Device` and `X-Client-userId` headers.
The API obtains application and KCF warehouse IDs from
`WM3_APPLICATION_ID` and `WM3_WAREHOUSE_MASTER_ID`.
