(* Desenvolvedor: Kelvin dos Santos Vieira
   Skype: nivlek_1995@hotmail.com
   Wpp: (49)99818-2190
   FB: https://www.facebook.com/keelvin9 *)

(* EnterTab: Componente para ajudar no controle de foco em FMX Windows*.
   Para usar: 1º. Coloque o componente na Form;
              2º. Configure a propriedade ControlarForm da seguinte maneira:
                  - True para que o componente controle os componentes de uma Form
                    (Usado em aberturas padrões de form [FORM.Show]);
                  - False para que o componente controle os componetes dentro de um Layout
                    (Usado em aberturas de Layouts [LayoutMain.AddObject(Form2.Layout)]);
              3º. Marque a opção EnterAsTab para ativar o evento de Controle;
              4º. Configure os componentes na sua form ou layout com os TabOrder corretamente;
              5º. Seja feliz!.
   * - Não testado em ambientes MacOS, Linux, Android ou IOS *)

unit uLazarusEnterTab;

interface

uses
  System.SysUtils, System.Classes, FMX.Forms, FMX.Types, System.UITypes,
  FMX.StdCtrls, FMX.Controls, System.Rtti, FMX.Edit;

type
  TLazarusEnterTab = class(TComponent)
  private
    { Private declarations }
    FListaControls: TList;
    FOwner: TForm;
    FOldKeyPreview : Boolean;
    FOldOnKeyPress : TKeyEvent;
    FEnterAsTab: boolean;
    FControlComponent: TComponent;
    FControlarForm: Boolean;
    procedure SetEnterAsTab(const Value: boolean);
    procedure SetControlComponent(const Value: TComponent);
    procedure SetControlarForm(const Value: Boolean);
  protected
    { Protected declarations }
  public
    { Public declarations }
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;

    procedure DoEnterAsTab(AForm : TObject;  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
    function SelectNextControl(ATabOrderAtual: Integer): TControl;
    function SelectControlFocused: TControl;
    procedure ListarControls;
    procedure PreencherListaComChildrens(AObj: TFMXObject);
  published
    { Published declarations }
    property EnterAsTab: boolean read FEnterAsTab write SetEnterAsTab;
    property ControlComponent: TComponent read FControlComponent write SetControlComponent;
    property ControlarForm: Boolean read FControlarForm write SetControlarForm;
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('LazarusUteis', [TLazarusEnterTab]);
end;

{ TLazarusEnterTab }

constructor TLazarusEnterTab.Create(AOwner: TComponent);
begin
  if not (AOwner is TForm) then
    raise Exception.Create('Owner tem que ser do tipo TForm');
  inherited Create(AOwner);
  FOwner := TForm(AOwner);
  (*Atribui o evento atual de KeyDown do controle a variavel do tipo TKeyEvent
    para se necessário voltar o evento antigo*)
  FOldOnKeyPress := FOwner.OnKeyDown;
  FListaControls := TList.Create;
  if not (csDesigning in ComponentState) then
  begin
    (*Se não for setado nenhum componente de controle de forms ele pega o Owner
      ou seja, a propria form como controle*)
    if FControlComponent = Nil then
      FControlComponent := AOwner;
  end;
end;

destructor TLazarusEnterTab.Destroy;
begin
  if Assigned(FOwner) then
  begin
    if not (csFreeNotification in FOwner.ComponentState) then
    begin
      FOwner.OnKeyDown := FOldOnKeyPress;
    end;
  end;
  inherited;
end;

procedure TLazarusEnterTab.DoEnterAsTab(AForm: TObject;  var Key: Word; var KeyChar: WideChar; Shift: TShiftState);
var
  vTabOrder: Integer;
  vProximoControl: TControl;
  vControlFocused: TControl;
begin
  (*Primeiramente o evento adiciona todos os TControls a um TList*)
  ListarControls;
  if not (AForm is TForm) then
    Exit;
  if (Key = vkReturn) or (Key = vkTab) then
  begin
    (*Busca o componente que está com o foco atualmente*)
    vControlFocused := SelectControlFocused;
    (*Pega o TabOrder dele para buscar o próximo posteriormente*)
    vTabOrder := vControlFocused.TabOrder;
    (*Se o componente que está em foco for um componente de Botão, então não muda foco. Apenas Clica*)
    if vControlFocused is TCustomButton then
    begin
      TButton(SelectControlFocused).OnClick(Nil);
    end
    else
    begin
      (*Caso contrário busca o proximo Componente a partir do TabOrder atual*)
      vProximoControl := SelectNextControl(vTabOrder);
      if vProximoControl <> Nil then
      begin
        (*Achado o componente, seta o foco ao mesmo*)
        vProximoControl.SetFocus;
      end;
    end;
  end;
  (*Para não executar o procedimento cábivel naturalmente a tecla pressionada*)
  if (Key = vkReturn) or (Key = vkTab) then
    KeyChar := #0;
end;

procedure TLazarusEnterTab.ListarControls;
begin
  (*Só lista os componentes se quem controla o foco é um TComponent setado na
    propriedade ControlComponent*)
  if not (FControlarForm) then
  begin
    (*Sempre Limpa a TList para quando abrir um novo form (Chamar o Layout)
      percorrer sua lista de Childrens*)
    FListaControls.Clear;
    (*Começa executando o procedimento de listagem pelo proprio componente
      responsável por exibir as forms (Layouts)*)
    PreencherListaComChildrens(TFMXObject(FControlComponent));
  end;
end;

procedure TLazarusEnterTab.PreencherListaComChildrens(AObj: TFMXObject);
var
  I,J: Integer;
begin
  for I := 0 to Pred(AObj.ChildrenCount) do
  begin
    (*Verifica se o Filho(Children) é do tipo TControl (Visual) e se o
      TabStop for True para poder adicionar a TList*)
    if (AObj.Children[i] is TControl) and
       (TControl(AObj.Children[i]).TabStop) then
    (*Adiciona o TControl a TList*)
    FListaControls.Add(AObj.Children[i]);
    (*Reexecuta o procedimento agora a partir do Filho na posição I*)
    PreencherListaComChildrens(AObj.Children[i]);
  end;
  (*Executará até não restarem mais filhos no Layout de Forms*)
end;

function TLazarusEnterTab.SelectControlFocused: TControl;
var
  I: Integer;
begin
  result := nil;
  (*Se for controlado por form, busca no componentcount o foco atual, caso
  contrário buscará nos filhos do componente setado na propriedade
  controlcomponent pelo foco atual*)
  if not (FControlarForm) then
  begin
    for I := 0 to Pred(FListaControls.Count) do
    begin
      if TControl(FListaControls[i]).IsFocused then
      begin
        result := TControl(FListaControls[i]);
        break;
      end;
    end;
  end
  else
  begin
    for I := 0 to Pred(FControlComponent.ComponentCount) do
    begin
      if (FControlComponent.Components[i] is TControl) and (TControl(FControlComponent.Components[i]).IsFocused) then
      begin
        result := TControl(FControlComponent.Components[i]);
        break;
      end;
    end;
  end;
end;

function TLazarusEnterTab.SelectNextControl(ATabOrderAtual: Integer): TControl;
var
  i: integer;
begin
  result := nil;
  (*Se for controlado por uma Form, roda o ComponentCount para pegar o
    proximo Control a receber foco, caso contrário faz um for nos filhos(Childrens)
    do controle atribuido a propriedade ControlComponent.
    Para isso ele precisa ser TControl e alem disso ser um TCustomEdit ou TCustomButton.
    Componentes como TComboBox, tem um [Enter] proprio que ao teclar enter,
    exibe a lista de itens do prorio componente*)
  if not (FControlarForm) then
  begin
    for I := 0 to Pred(FListaControls.Count) do
    begin
      if ((TControl(FListaControls[i]) is TCustomEdit) or (TControl(FListaControls[i]) is TCustomButton)) and
         (TControl(FListaControls[i]).TabStop) and
         (TControl(FListaControls[i]).TabOrder = ATabOrderAtual + 1) then
      begin
        result := TControl(FListaControls[i]);
        break;
      end;
    end;
  end
  else
  begin
    for I := 0 to Pred(FControlComponent.ComponentCount) do
    begin
      if (FControlComponent.Components[i] is TControl) and ((TControl(FControlComponent.Components[i]) is TCustomEdit) or (TControl(FControlComponent.Components[i]) is TCustomButton)) and
         (TControl(FControlComponent.Components[i]).TabOrder = (ATabOrderAtual + 1)) and
         (TControl(FControlComponent.Components[i]).TabStop) then
      begin
        result := TControl(FControlComponent.Components[i]);
        break;
      end;
    end;
  end;
end;

procedure TLazarusEnterTab.SetControlarForm(const Value: Boolean);
begin
  FControlarForm := Value;
end;

procedure TLazarusEnterTab.SetControlComponent(const Value: TComponent);
begin
  FControlComponent := Value;
end;

procedure TLazarusEnterTab.SetEnterAsTab(const Value: boolean);
begin
  if Value = FEnterAsTab then exit ;

  if not (csDesigning in ComponentState) then
  begin
     with TForm( Owner ) do
     begin
        if Value then
         begin
           (*Se marcado seta o evento criado no componente para o KeyDown da Form*)
           OnKeyDown := DoEnterAsTab;
         end
        else
         begin
           (*Se desmarcado seta o evento anterior da form ao evento KeyDown da Form*)
           OnKeyDown := FOldOnKeyPress;
         end ;
     end ;
  end ;

  FEnterAsTab := Value;
end;

end.
