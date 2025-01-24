#Include "Totvs.ch"
#Include "RESTFul.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} zWsPedidos
@type WSRESTFUL
@description WebService para consulta de pedidos de venda
@author  Filipe F S Nantes
@since   23/01/2025
@version 1.1
/*/
//-------------------------------------------------------------------

WSRESTFUL zWsPedidos DESCRIPTION "WebService para consulta de pedidos de venda"
    // Atributos
    WSDATA id AS STRING // Número do pedido (C5_NUM / C6_NUM)
    WSDATA filial AS STRING // Filial do pedido (C5_FILIAL / C6_FILIAL)

    // Métodos
    WSMETHOD GET ID DESCRIPTION "Retorna o status e os itens do pedido" WSSYNTAX "/zWsPedidos/get_id?{filial,id}" PATH "get_id" PRODUCES APPLICATION_JSON
END WSRESTFUL

//-------------------------------------------------------------------
/*/{Protheus.doc} zWsPedidos.GET()
@type WSMETHOD
@description Retorna o status e os itens do pedido
@author  Filipe F S Nantes
@since   23/01/2025
@version 1.7
/*/
//-------------------------------------------------------------------

WSMETHOD GET ID WSRECEIVE filial, id WSSERVICE zWsPedidos
    Local lRet := .T.
    Local jResponse := JsonObject():New()
    Local cAliasSC5 := "SC5"
    Local cAliasSC6 := "SC6"
    Local oItem
    Local aItens := {}

    // Validação dos parâmetros
    If Empty(::filial) .Or. Empty(::id)
        Self:setStatus(500)
        jResponse["errorId"] := "ID001"
        jResponse["error"] := "Filial ou número do pedido não informados"
        jResponse["solution"] := "Informe a filial e o número do pedido para prosseguir"
    Else
        // Busca o status do pedido na SC5
        DbSelectArea(cAliasSC5)
        (cAliasSC5)->(DbSetOrder(1)) // Define a ordem na chave C5_FILIAL + C5_NUM
        If !(cAliasSC5)->(MsSeek(::filial + ::id))
            Self:setStatus(404)
            jResponse["errorId"] := "ID003"
            jResponse["error"] := "Pedido não encontrado"
            jResponse["solution"] := "O pedido informado não foi encontrado na tabela SC5"
        Else
            // Adiciona o status do pedido ao JSON
            jResponse["status"] := (cAliasSC5)->C5_STATUS
            jResponse["filial"] := (cAliasSC5)->C5_FILIAL
            jResponse["num"] := (cAliasSC5)->C5_NUM
            jResponse["cliente"] := (cAliasSC5)->C5_CLIENTE

            // Busca os itens do pedido na SC6
            DbSelectArea(cAliasSC6)
            (cAliasSC6)->(DbSetOrder(1)) // Define a ordem na chave C6_FILIAL + C6_NUM
            (cAliasSC6)->(DbGoTop())

            While !(cAliasSC6)->(EoF())
                If (cAliasSC6)->C6_FILIAL + (cAliasSC6)->C6_NUM == ::filial + ::id
                    oItem := JsonObject():New()
                    oItem["filial"] := (cAliasSC6)->C6_FILIAL
                    oItem["item"] := (cAliasSC6)->C6_ITEM
                    oItem["produto"] := (cAliasSC6)->C6_PRODUTO
                    oItem["descricao"] := (cAliasSC6)->C6_DESCRI
                    oItem["quantidade"] := (cAliasSC6)->C6_QTDVEN
                    oItem["unidade"] := (cAliasSC6)->C6_UM
                    oItem["valor_unitario"] := (cAliasSC6)->C6_PRCVEN
                    oItem["valor_total"] := (cAliasSC6)->C6_VALOR
                    oItem["tes"] := (cAliasSC6)->C6_TES
                    oItem["cf"] := (cAliasSC6)->C6_CF
                    aAdd(aItens, oItem)
                EndIf
                (cAliasSC6)->(DbSkip())
            EndDo

            // Verifica se encontrou itens
            If Len(aItens) == 0
                Self:setStatus(404)
                jResponse["errorId"] := "ID002"
                jResponse["error"] := "Itens não encontrados"
                jResponse["solution"] := "Não foram encontrados itens para o pedido informado"
            Else
                jResponse["itens"] := aItens

                // Simula a integração com um serviço externo
                jResponse["servico_externo"] := MockServicoExterno(::id)
                Self:setStatus(200)
            EndIf
        EndIf
    EndIf

    // Define o retorno
    Self:SetContentType("application/json")
    Self:SetResponse(EncodeUTF8(jResponse:toJSON()))
Return lRet

Static Function MockServicoExterno(cIdPedido)
    Local oMockResponse := JsonObject():New()

    // Simula a resposta do serviço externo
    oMockResponse["id"] := cIdPedido
    oMockResponse["status"] := "Aprovado"
    oMockResponse["message"] := "Pedido encontrado no serviço externo"

Return oMockResponse
