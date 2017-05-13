module Main exposing (..)

import Dropdown exposing (dropdown, toggle, drawer, ToggleEvent(..))
import Html exposing (..)
import Html.Attributes exposing (class)


main : Program Never Model Msg
main =
    Html.program
        { init = init ! []
        , update = update
        , view = view
        , subscriptions = (\_ -> Sub.none)
        }


init : Model
init =
    { myDropdown = False }


type alias Model =
    { myDropdown : Dropdown.State }


type Msg
    = ToggleDropdown Bool


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        ToggleDropdown newState ->
            ( { model | myDropdown = newState }, Cmd.none )


view : Model -> Html Msg
view model =
    div []
        [ dropdown
            model.myDropdown
            myDropdownConfig
            (toggle button [] [ text "Toggle" ])
            (drawer div
                []
                [ button [] [ text "Option 1" ]
                , button [] [ text "Option 2" ]
                , button [] [ text "Option 3" ]
                ]
            )
        ]


myDropdownConfig : Dropdown.Config Msg
myDropdownConfig =
    Dropdown.Config
        "myDropdown"
        OnClick
        (class "visible")
        ToggleDropdown
