@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Bill Item Interface'
@Metadata.ignorePropagatedAnnotations: true
define view entity ZCIT_BI_IN_22EC086 as select from zcit_b_i_22ec086 association to parent ZCIT_BH_I_22EC086 as _Header
  on $projection.BillUuid = _Header.BillUuid
{
     key item_uuid     as ItemUuid,

        bill_uuid     as BillUuid,
        item_position as ItemPosition,
        product_id    as ProductId,
        quantity      as Quantity,

        @Semantics.amount.currencyCode: 'Currency'
        unit_price    as UnitPrice,

        @Semantics.amount.currencyCode: 'Currency'
        subtotal      as Subtotal,

        currency      as Currency,
        _Header

}
