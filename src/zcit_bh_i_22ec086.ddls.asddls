@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill header interface'
@Metadata.ignorePropagatedAnnotations: true
define root view entity ZCIT_BH_I_22EC086 as select from zcit_b_h_22ec086 composition [0..*] of ZCIT_BI_IN_22EC086 as _Items

{
     key bill_uuid     as BillUuid,

        bill_number   as BillNumber,
        customer_name as CustomerName,
        billing_date  as BillingDate,

        @Semantics.amount.currencyCode: 'Currency'
        total_amount  as TotalAmount,

        currency      as Currency,

        payment_status as PaymentStatus,
        _Items
        

        
}
