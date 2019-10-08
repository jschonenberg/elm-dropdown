# elm-dropdown
`elm-dropdown` offers a flexible component which can serve as a foundation for custom dropdowns, select-inputs, popovers, and more.

#### History

A big thank you [jschonenberg](https://github.com/jschonenberg) who originally authored this package.
This version is a slightly modified version updated for Elm 0.19 and fixes, refactoring.
Please be aware that usage is not completely identical to the original.

#### Features

* Pure, state gets passed in from the parent.
* Use any HTML-element as toggle or drawer.
* Choose for toggle on on click, hover, or focus.
* Supports keyboard navigation (`tab`, `esc`).
* No backdrop-element, direct interaction with other elements is possible.
* Unassuming about visual style, bring your own CSS.

#### Example

Basic example of use:

```elm
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
            , isToggled = myDropdownIsOpen
            }
        ]
```
