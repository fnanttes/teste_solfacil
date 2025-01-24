// Bibliotecas
#Include "Totvs.ch"
#Include "RESTFul.ch"

/*/{Protheus.doc} zWsPedidos
 * WebService para consulta de pedidos de venda
 * @author Filipe Ferreira da Silva Nantes
 * @since 24/01/2025
 * @version 1.1
 * @type function
 * @description Servi�o RESTful para consulta de pedidos de venda na tabela SC5.
 * @obs Necess�rio autentica��o via Bearer Token.
 * @response Retorna JSON com os dados do pedido, incluindo:
 * - filial
 * - n�mero
 * - tipo
 * - cliente
 * - condi��o de pagamento
 * - valor total
 * - status
 * @error 400 - ID n�o informado.
 * @error 401 - Token inv�lido ou ausente.
 * @error 404 - Pedido n�o encontrado.
/*/

WSRESTFUL zWsPedidos DESCRIPTION 'WebService para consulta de pedidos de venda'
    // Atributos
    WSDATA id AS STRING
    // M�todos
    WSMETHOD GET ID DESCRIPTION 'Retorna o registro pesquisado' WSSYNTAX '/zWsPedidos/get_id?{id}' PATH 'get_id' PRODUCES APPLICATION_JSON
END WSRESTFUL

/*/{Protheus.doc} GET ID
 * Busca registro via ID com autentica��o e resili�ncia
 * @type method
 * @param id, Character, String que ser� pesquisada atrav�s do MsSeek
 * @param Authorization, Header, Bearer Token de autentica��o
/*/

WSMETHOD GET ID WSRECEIVE id WSSERVICE zWsPedidos
    Local lRet := .T.
    Local jResponse := JsonObject():New()
    Local cAliasWS := 'SC5'
    Local cBearerToken := Self:GetHeader("Authorization")

    // Valida��o do Bearer Token
    If !ValidaToken(cBearerToken)
        Self:setStatus(401)
        jResponse['error'] := "Token inv�lido ou ausente"
        jResponse['solution'] := "Forne�a um token v�lido no header Authorization"
        Self:SetResponse(EncodeUTF8(jResponse:toJSON()))
        Return .F.
    EndIf

    // Valida��o do ID
    If Empty(::id)
        Self:setStatus(400)
        jResponse['error'] := "ID do pedido n�o informado"
        jResponse['solution'] := "Informe um ID v�lido no endpoint"
        Self:SetResponse(EncodeUTF8(jResponse:toJSON()))
        Return .F.
    EndIf

    // Busca o cabe�alho do pedido (SC5)
    DbSelectArea(cAliasWS)
    (cAliasWS)->(DbSetOrder(1)) // Define a ordem no �ndice do ID
    Begin Sequence
        If ! (cAliasWS)->(MsSeek(FWxFilial(cAliasWS) + ::id))
            Self:setStatus(404)
            jResponse['error'] := "Pedido n�o encontrado"
            jResponse['solution'] := "Verifique se o ID informado est� correto"
        Else
            // Preenche os dados do pedido no JSON
            jResponse['filial'] := (cAliasWS)->C5_FILIAL
            jResponse['num'] := (cAliasWS)->C5_NUM
            jResponse['tipo'] := (cAliasWS)->C5_TIPO
            jResponse['cliente'] := (cAliasWS)->C5_CLIENTE
            jResponse['condpag'] := (cAliasWS)->C5_CONDPAG
            jResponse['total'] := (cAliasWS)->C5_TOTAL
            jResponse['status'] := (cAliasWS)->C5_STATUS
            Self:setStatus(200)
        EndIf
        Recover
        Self:setStatus(500)
        jResponse['error'] := "Erro interno no servidor"
        jResponse['solution'] := "Entre em contato com o suporte t�cnico"
    End Sequence

    // Define o retorno
    Self:SetContentType('application/json')
    Self:SetResponse(EncodeUTF8(jResponse:toJSON()))
Return lRet

/*/{Protheus.doc} ValidaToken
 * Fun��o para validar o Bearer Token.
 * @type function
 * @param cToken, String, Token enviado no cabe�alho Authorization.
 * @response Boolean, Verdadeiro se o token for v�lido, Falso caso contr�rio.
 * @description Valida se o token fornecido � igual ao token esperado.
/*/

Static Function ValidaToken(cToken)
    Local cExpectedToken := "Bearer 12345@ABCDE"
    If Empty(cToken) .Or. cToken # cExpectedToken
        Return .F.
    EndIf
Return .T.
