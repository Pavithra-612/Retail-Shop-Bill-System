@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Item Consumption'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true  
define view entity ZCIT_BI_CV_22EC086 as projection on ZCIT_BI_IN_22EC086
{
   key ItemUuid,

    BillUuid,

    @UI.lineItem: [{ position: 10 }]
    ItemPosition,

    @UI.lineItem: [{ position: 20 }]
    ProductId,

    @UI.lineItem: [{ position: 30 }]
    Quantity,

    @Semantics.amount.currencyCode: 'Currency'
    @UI.lineItem: [{ position: 40 }]
    UnitPrice,

    @Semantics.amount.currencyCode: 'Currency'
    @UI.lineItem: [{ position: 50 }]
    Subtotal,

    @UI.lineItem: [{ position: 60 }]
    Currency,
    _Header : redirected to parent ZCIT_BH_C_22EC086
}
