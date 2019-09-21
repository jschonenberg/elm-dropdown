module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Dropdown exposing (dropdown)
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
    { myDropdownIsOpen = False }


type alias Model =
    { myDropdownIsOpen : Dropdown.State }


type Msg
    = ToggleDropdown Bool


update : Msg -> Model -> Model
update msg model =
    case msg of
        ToggleDropdown newState ->
            { model | myDropdownIsOpen = newState }


view : Model -> Html Msg
view { myDropdownIsOpen } =
    div []
        [ dropdown
            { identifier = "my-dropdown"
            , toggleEvent = Dropdown.OnClick
            , drawerVisibleAttribute = class "visible"
            , onToggle = ToggleDropdown
            , layout =
                \{ toDropdown, toToggle, toDrawer } ->
                    toDropdown div
                        []
                        [ toToggle button [] [ text "Toggle" ]
                        , toDrawer div
                            []
                            [ button [] [ text "Option 1" ]
                            , button [] [ text "Option 2" ]
                            , button [] [ text "Option 3" ]
                            ]
                        ]
            }
            myDropdownIsOpen
        ]
