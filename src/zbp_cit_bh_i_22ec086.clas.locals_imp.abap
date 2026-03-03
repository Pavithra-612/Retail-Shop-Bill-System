CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    TYPES: tt_header TYPE STANDARD TABLE OF zcit_b_h_22ec086 WITH EMPTY KEY,
           tt_items  TYPE STANDARD TABLE OF zcit_b_i_22ec086 WITH EMPTY KEY.

    CLASS-DATA: mt_header         TYPE tt_header,
                mt_items          TYPE tt_items,
                " This line fixes the 'invalid' error:
                mt_deleted_header TYPE tt_header.
ENDCLASS.


CLASS lhc_ZCIT_BH_I_22EC086 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR zcit_bh_i_22ec086 RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR zcit_bh_i_22ec086 RESULT result.

    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE zcit_bh_i_22ec086.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zcit_bh_i_22ec086.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zcit_bh_i_22ec086.

    METHODS read FOR READ
      IMPORTING keys FOR READ zcit_bh_i_22ec086 RESULT result.

    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK zcit_bh_i_22ec086.

    METHODS rba_Items FOR READ
      IMPORTING keys_rba FOR READ zcit_bh_i_22ec086\_Items FULL result_requested RESULT result LINK association_links.

    METHODS cba_Items FOR MODIFY
      IMPORTING entities_cba FOR CREATE zcit_bh_i_22ec086\_Items.

ENDCLASS.

CLASS lhc_ZCIT_BH_I_22EC086 IMPLEMENTATION.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  " Implementation for global create authorization [cite: 83]
    IF requested_authorizations-%create = if_abap_behv=>mk-on.
      result-%create = if_abap_behv=>auth-allowed.
    ENDIF.
  ENDMETHOD.

  METHOD create.
   " 1. Define local structure matching your DB table ZBILL_HDR
  DATA ls_header_db TYPE zcit_b_h_22ec086.

  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
    CLEAR ls_header_db.

    " 2. RECTIFICATION: Use MAPPING FROM ENTITY to filter technical fields
    ls_header_db = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).

    " 3. Manually set the Client (Mandatory for Unmanaged)
    ls_header_db-client = sy-mandt.

    " 4. Manual UUID generation (as numbering:managed isn't supported)
    TRY.
        ls_header_db-bill_uuid = cl_system_uuid=>create_uuid_x16_static( ).
      CATCH cx_uuid_error.
        " Handle error appropriately
    ENDTRY.

    " 5. Insert into local buffer [cite: 87]
    INSERT ls_header_db INTO TABLE lcl_buffer=>mt_header.

    " 6. Report mapped ID back to framework using CDS field name
    APPEND VALUE #( %cid     = <entity>-%cid
                    BillUuid = ls_header_db-bill_uuid )
           TO mapped-zcit_bh_i_22ec086.
  ENDLOOP.
  ENDMETHOD.

  METHOD update.
  LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      READ TABLE lcl_buffer=>mt_header WITH KEY bill_uuid = <entity>-BillUuid ASSIGNING FIELD-SYMBOL(<header>).
      IF sy-subrc = 0.
        <header> = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
  LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
    " Append the record to be deleted to our new buffer table
    APPEND VALUE #( bill_uuid = <key>-BillUuid ) TO lcl_buffer=>mt_deleted_header.

    " Remove from the display buffers
    DELETE lcl_buffer=>mt_header WHERE bill_uuid = <key>-BillUuid.
    DELETE lcl_buffer=>mt_items  WHERE bill_uuid = <key>-BillUuid.
  ENDLOOP.
  ENDMETHOD.

  METHOD read.
  ENDMETHOD.

  METHOD lock.
  ENDMETHOD.

  METHOD rba_Items.
  LOOP AT keys_rba ASSIGNING FIELD-SYMBOL(<ls_key>).
      " Look into the buffer for items belonging to THIS specific header UUID
      LOOP AT lcl_buffer=>mt_items ASSIGNING FIELD-SYMBOL(<ls_item>)
           WHERE bill_uuid = <ls_key>-BillUuid.

        IF result_requested = abap_true.
          " Fill the result table so the UI can display the data
          APPEND CORRESPONDING #( <ls_item> MAPPING TO ENTITY ) TO result.
        ENDIF.

        " Fill association_links to tell RAP which Item belongs to which Header
        APPEND VALUE #( source-%key = <ls_key>-%key
                        target-%key = VALUE #( ItemUuid = <ls_item>-item_uuid ) )
               TO association_links.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

  METHOD cba_Items.
LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_entity>).
      DATA(lv_bill_uuid) = <ls_entity>-BillUuid.

      LOOP AT <ls_entity>-%target ASSIGNING FIELD-SYMBOL(<ls_new_item>).
        DATA ls_item TYPE zcit_b_i_22ec086.
        ls_item = CORRESPONDING #( <ls_new_item> MAPPING FROM ENTITY ).
        ls_item-bill_uuid = lv_bill_uuid.
        ls_item-item_uuid = cl_system_uuid=>create_uuid_x16_static( ).

        APPEND ls_item TO lcl_buffer=>mt_items.

        " FIX: Must use the ITEM entity name from the BASE BDEF
        APPEND VALUE #( %cid     = <ls_new_item>-%cid
                        ItemUuid = ls_item-item_uuid )
               TO mapped-zcit_bi_in_22ec086.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.

ENDCLASS.

CLASS lhc_ZCIT_BI_IN_22EC086 DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE zcit_bi_in_22ec086.

    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE zcit_bi_in_22ec086.

    METHODS read FOR READ
      IMPORTING keys FOR READ zcit_bi_in_22ec086 RESULT result.

    METHODS rba_Header FOR READ
      IMPORTING keys_rba FOR READ zcit_bi_in_22ec086\_Header FULL result_requested RESULT result LINK association_links.

ENDCLASS.

CLASS lhc_ZCIT_BI_IN_22EC086 IMPLEMENTATION.

  METHOD update.
  " Implementation for updating items in the local buffer
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<entity>).
      " Find the item in the global buffer using its UUID
      READ TABLE lcl_buffer=>mt_items WITH KEY item_uuid = <entity>-ItemUuid
           ASSIGNING FIELD-SYMBOL(<item_db>).

      IF sy-subrc = 0.
        " RECTIFICATION: Use MAPPING FROM ENTITY to satisfy Strict(2)
        " This updates only the fields provided in the %control structure
        <item_db> = CORRESPONDING #( <entity> MAPPING FROM ENTITY ).
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD delete.
  " Implementation for deleting items from the local buffer
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      DELETE lcl_buffer=>mt_items WHERE item_uuid = <key>-ItemUuid.
    ENDLOOP.
  ENDMETHOD.

  METHOD read.
  " Standard READ implementation for unmanaged items
    LOOP AT keys ASSIGNING FIELD-SYMBOL(<key>).
      READ TABLE lcl_buffer=>mt_items WITH KEY item_uuid = <key>-ItemUuid
           ASSIGNING FIELD-SYMBOL(<item_db>).
      IF sy-subrc = 0.
        APPEND CORRESPONDING #( <item_db> MAPPING TO ENTITY ) TO result.
      ENDIF.
    ENDLOOP.
  ENDMETHOD.

  METHOD rba_Header.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZCIT_BH_I_22EC086 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS finalize REDEFINITION.

    METHODS check_before_save REDEFINITION.

    METHODS save REDEFINITION.

    METHODS cleanup REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZCIT_BH_I_22EC086 IMPLEMENTATION.

  METHOD finalize.
  ENDMETHOD.

  METHOD check_before_save.
  ENDMETHOD.

  METHOD save.
 " 1. Delete only the Headers specifically marked for deletion
  IF lcl_buffer=>mt_deleted_header IS NOT INITIAL.
    DELETE zcit_b_h_22ec086 FROM TABLE @lcl_buffer=>mt_deleted_header.
  ENDIF.

  " 2. Save all Headers (New and Updated) from the buffer
  IF lcl_buffer=>mt_header IS NOT INITIAL.
    MODIFY zcit_b_h_22ec086 FROM TABLE @lcl_buffer=>mt_header.
  ENDIF.

  " 3. Save all Items (This includes the new items from cba_Items)
  IF lcl_buffer=>mt_items IS NOT INITIAL.
    MODIFY zcit_b_i_22ec086 FROM TABLE @lcl_buffer=>mt_items.
  ENDIF.
  ENDMETHOD.

  METHOD cleanup.
  CLEAR: lcl_buffer=>mt_header,
         lcl_buffer=>mt_items,
         lcl_buffer=>mt_deleted_header.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
