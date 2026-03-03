@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Header Consumption'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true  

@UI.headerInfo: {
  typeName: 'Bill',
  typeNamePlural: 'Bills',
  title: { value: 'BillNumber' }
}
define root view entity ZCIT_BH_C_22EC086 provider contract transactional_query as projection on ZCIT_BH_I_22EC086 
{
   key BillUuid,

    @UI.lineItem: [{ position: 10 }]
    @UI.identification: [{ position: 10 }]
    BillNumber,

    @UI.lineItem: [{ position: 20 }]
    @UI.identification: [{ position: 20 }]
    CustomerName,

    @UI.lineItem: [{ position: 30 }]
    @UI.identification: [{ position: 30 }]
    BillingDate,

    @Semantics.amount.currencyCode: 'Currency'
    @UI.lineItem: [{ position: 40 }]
    @UI.identification: [{ position: 40 }]
    TotalAmount,

    @UI.lineItem: [{ position: 50 }]
    @UI.identification: [{ position: 50 }]
    Currency,

    @UI.lineItem: [{ position: 60 }]
    @UI.identification: [{ position: 60 }]
    PaymentStatus,

    _Items : redirected to composition child ZCIT_BI_CV_22EC086
}
