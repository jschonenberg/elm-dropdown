module Main exposing (Model, Msg(..), init, main, myDropdownConfig, update, view)

import Browser
import Dropdown exposing (ToggleEvent(..), drawer, dropdown, toggle)
import Html exposing (..)
import Html.Attributes exposing (class)


main : Program () Model Msg
main =
    Browser.sandbox
        { init = init
        , view = view
        , update = update
        }


init : Model
init =
    { myDropdown = False }


type alias Model =
    { myDropdown : Dropdown.State }


type Msg
    = ToggleDropdown Bool


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleDropdown newState ->
            { model | myDropdown = newState }


view : Model -> Html Msg
view { myDropdown } =
    div []
        [ dropdown
            myDropdownConfig
            myDropdown
            div
            []
            [ \config state ->
                toggle config state button [] [ text "Toggle" ]
            , \config state ->
                drawer config
                    state
                    div
                    []
                    [ button [] [ text "Option 1" ]
                    , button [] [ text "Option 2" ]
                    , button [] [ text "Option 3" ]
                    ]
            ]
        ]


myDropdownConfig : Dropdown.Config Msg
myDropdownConfig =
    { identifier = "myDropdown"
    , toggleEvent = Dropdown.OnClick
    , drawerVisibleAttribute = class "visible"
    , onToggle = ToggleDropdown
    }
