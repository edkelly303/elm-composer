module Form exposing (main)

import Browser
import Composer.Element exposing (..)
import Html
import Html.Attributes
import Html.Events
import Http
import Process
import Task
import Time



-- DOMAIN TYPES & DATA


type alias User =
    { name : String
    , age : Int
    , cool : Bool
    , petId : Int
    , toyId : Int
    }


type alias Pet =
    { name : String
    , id : Int
    }


pets : List Pet
pets =
    [ { id = 1, name = "Fido" }
    , { id = 2, name = "Miaowcus" }
    ]


type alias Toy =
    { id : Int
    , name : String
    , petId : Int
    }


petToys : List Toy
petToys =
    [ { id = 1, name = "Juicy bone", petId = 1 }
    , { id = 2, name = "Fluffy penguin", petId = 1 }
    , { id = 3, name = "Big stick", petId = 1 }
    , { id = 4, name = "Ball of string", petId = 2 }
    , { id = 5, name = "Laser pointer", petId = 2 }
    ]



-- PROGRAM TYPES AND MAIN


type ProgMsg
    = FormMsg FormMsg
    | ToysLoaded (Result Http.Error (List Toy))


type alias ProgModel =
    { form : FormModel
    , toys : List Toy
    }


main : Program () ProgModel ProgMsg
main =
    Browser.element
        { init =
            \_ ->
                let
                    ( formModel, formCmd ) =
                        form.init ()
                in
                ( { form = formModel, toys = [] }
                , Cmd.map FormMsg formCmd
                )
        , update =
            \msg model ->
                case msg of
                    ToysLoaded (Ok toys) ->
                        ( { model | toys = toys }
                        , Cmd.none
                        )

                    ToysLoaded (Err _) ->
                        ( model
                        , Cmd.none
                        )

                    FormMsg formMsg ->
                        let
                            requestToys =
                                -- peek into the form msg and react if necessary
                                case peek formMsg of
                                    Just (PetUpdated maybePetId) ->
                                        -- simulate requesting the list of toys from an API somewhere
                                        Http.get
                                            { expect =
                                                Http.expectString
                                                    (\_ ->
                                                        petToys
                                                            |> List.filter (\toy -> Just toy.petId == maybePetId)
                                                            |> Ok
                                                            |> ToysLoaded
                                                    )
                                            , url = "http://localhost:8000/clock.html"
                                            }

                                    _ ->
                                        Cmd.none

                            ( formModel, formCmd ) =
                                form.update formMsg model.form
                        in
                        ( { model | form = formModel }
                        , Cmd.batch
                            [ requestToys
                            , Cmd.map FormMsg formCmd
                            ]
                        )
        , view =
            \model ->
                -- we can pass extra args into the form.view, but we need to pass the form model in first
                -- this wouldn't work if we tried to do `form.view model.toys model.form`
                form.view model.form model.toys
                    |> Html.map FormMsg
        , subscriptions =
            \model ->
                form.subscriptions model.form
                    |> Sub.map FormMsg
        }


peek ( appMsg, _ ) =
    appMsg



-- FORM TYPES AND DEFINITION


type alias FormModel =
    ( AppModel
    , ( InputModel String String
      , ( InputModel String Int
        , ( InputModel Bool Bool
          , ( InputModel { selected : Maybe Int, filter : String } Int
            , ( InputModel { selected : Maybe Int, filter : String } Int
              , ()
              )
            )
          )
        )
      )
    )


type alias FormMsg =
    ( Maybe AppMsg
    , ( Maybe TextInputMsg
      , ( Maybe TextInputMsg
        , ( Maybe BoolInputMsg
          , ( Maybe (SelectInputMsg Int)
            , ( Maybe (SelectInputMsg Int)
              , ()
              )
            )
          )
        )
      )
    )


form =
    defineForm app
        (\name age cool pet toy ->
            { name = name
            , age = age
            , cool = cool
            , pet = pet
            , toy = toy
            }
        )
        |> withStringField "Name"
        |> withIntField "Age"
        |> withBoolField "Is cool?"
        |> withSelectField "Pet" PetUpdated
        |> withSelectField "Toy" ToyUpdated
        |> endForm


defineForm shared grouper =
    { fields = integrate shared
    , grouper = grouper
    }


withStringField label builder =
    { fields =
        builder.fields
            |> withSimpleComponent (string label)
    , grouper = builder.grouper
    }


withIntField label builder =
    { fields =
        builder.fields
            |> withSimpleComponent (int label)
    , grouper = builder.grouper
    }


withBoolField label builder =
    { fields =
        builder.fields
            |> withSimpleComponent (bool label)
    , grouper = builder.grouper
    }


withSelectField label msg builder =
    { fields =
        builder.fields
            |> withComponent
                (select label)
                (\toApp _ ->
                    { selectionUpdated =
                        \maybeSelection ->
                            toApp (msg maybeSelection)
                    }
                )
    , grouper = builder.grouper
    }


endForm builder =
    builder.fields
        |> groupedAs builder.grouper



-- APP TYPES & DEFINITION


type AppMsg
    = SubmitClicked
    | BackClicked
    | PetUpdated (Maybe Int)
    | ToyUpdated (Maybe Int)


type alias AppModel =
    { page : AppPage }


type AppPage
    = FormActive
    | Success User


app =
    let
        validate name age cool pet toy =
            succeed
                (\name_ { age_, cool_ } pet_ toy_ ->
                    User name_ age_ cool_ pet_ toy_
                )
                |> check name.parsed
                |> check
                    (multi2
                        (\age_ cool_ ->
                            if cool_ && age_ > 40 then
                                Err [ ( "Is cool?", String.fromInt age_ ++ " is too old to be cool" ) ]

                            else
                                Ok { age_ = age_, cool_ = cool_ }
                        )
                        age.parsed
                        cool.parsed
                    )
                |> check pet.parsed
                |> check toy.parsed
    in
    { init =
        \_ _ () ->
            ( { page = FormActive }, Cmd.none )
    , update =
        \{ name, age, cool, pet, toy } _ msg model ->
            case msg of
                SubmitClicked ->
                    case validate name age cool pet toy of
                        Ok user ->
                            ( { model | page = Success user }
                            , Cmd.batch
                                [ send name.reset
                                , send age.reset
                                , send cool.reset
                                , send pet.reset
                                , send toy.reset
                                ]
                            )

                        Err _ ->
                            ( { model | page = FormActive }
                            , Cmd.batch
                                [ send name.touch
                                , send age.touch
                                , send cool.touch
                                , send pet.touch
                                , send toy.touch
                                ]
                            )

                BackClicked ->
                    ( { model | page = FormActive }
                    , Cmd.none
                    )

                PetUpdated maybePetId ->
                    let
                        _ =
                            Debug.log "Pet id changed" maybePetId
                    in
                    ( model, send toy.reset )

                ToyUpdated maybeToyId ->
                    let
                        _ =
                            Debug.log "Toy id changed" maybeToyId
                    in
                    ( model, Cmd.none )
    , view =
        \{ name, age, cool, pet, toy } toSelf model toys ->
            case model.page of
                FormActive ->
                    let
                        errors =
                            case validate name age cool pet toy of
                                Err errs_ ->
                                    errs_

                                Ok _ ->
                                    []
                    in
                    Html.form []
                        [ Html.h1 [] [ Html.text "Create a user" ]
                        , name.view errors
                        , age.view errors
                        , cool.view errors
                        , pet.view
                            { toId = .id
                            , toHtml = .name >> Html.text
                            , toString = .name
                            , items = pets
                            , errors = errors
                            }
                        , toy.view
                            { toId = .id
                            , toHtml = .name >> Html.text
                            , toString = .name
                            , items = toys
                            , errors = errors
                            }
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf SubmitClicked)
                            ]
                            [ Html.text "Submit!" ]
                        ]

                Success user ->
                    Html.div []
                        [ Html.text ("Hello " ++ user.name)
                        , Html.button
                            [ Html.Attributes.type_ "button"
                            , Html.Events.onClick (toSelf BackClicked)
                            ]
                            [ Html.text "Go back!" ]
                        ]
    , subscriptions =
        \_ _ _ ->
            Sub.none
    }


send msg =
    Task.perform identity (Task.succeed msg)



-- VALIDATION FUNCTIONS


succeed =
    Ok


check statusArg resCtor =
    case ( statusArg, resCtor ) of
        ( Touched (Ok arg), Ok ctor ) ->
            Ok (ctor arg)

        ( Touched (Ok _), Err errs ) ->
            Err errs

        ( Touched (Err errs), Ok _ ) ->
            Err errs

        ( Touched (Err errs1), Err errs2 ) ->
            Err (errs2 ++ errs1)

        ( _, Err errs ) ->
            Err errs

        ( _, Ok _ ) ->
            Err []


multi2 f status1 status2 =
    case ( status1, status2 ) of
        ( Touched (Ok arg1), Touched (Ok arg2) ) ->
            Touched (f arg1 arg2)

        ( Touched (Ok _), Touched (Err errs) ) ->
            Touched (Err errs)

        ( Touched (Err errs), Touched (Ok _) ) ->
            Touched (Err errs)

        ( Touched (Err errs1), Touched (Err errs2) ) ->
            Touched (Err (errs2 ++ errs1))

        ( Touched (Err errs), _ ) ->
            Touched (Err errs)

        ( _, Touched (Err errs) ) ->
            Touched (Err errs)

        ( _, _ ) ->
            Touched (Err [])



-- COMPONENT TYPES & DEFINITIONS


type alias InputModel value parsed =
    { status : InputStatus parsed, value : value }


type InputStatus parsed
    = Intact
    | Debouncing Time.Posix
    | Touched (Result (List ( String, String )) parsed)



-- TEXT INPUTS


type TextInputMsg
    = Text_Changed String
    | Text_Touched
    | Text_Reset
    | Text_DebounceStarted Time.Posix
    | Text_DebounceChecked Time.Posix


string label =
    textInput
        (\str ->
            if String.isEmpty str then
                Err [ ( label, "Name must not be blank" ) ]

            else
                Ok str
        )
        label


int label =
    textInput
        (\str ->
            case String.toInt str of
                Just i ->
                    Ok i

                Nothing ->
                    Err [ ( label, "Age must be an integer" ) ]
        )
        label


textInput parse label =
    let
        init =
            ( { value = ""
              , status = Intact
              }
            , Cmd.none
            )
    in
    { interface =
        \toSelf model ->
            { view = \errs -> textInputView label model errs |> Html.map toSelf
            , parsed = model.status
            , touch = toSelf Text_Touched
            , reset = toSelf Text_Reset
            }
    , init =
        \_ ->
            init
    , update =
        \msg model ->
            case msg of
                Text_Changed str ->
                    ( { model | value = str }
                    , Task.perform Text_DebounceStarted Time.now
                    )

                Text_Reset ->
                    init

                Text_Touched ->
                    ( { model
                        | status =
                            case model.status of
                                Touched _ ->
                                    model.status

                                _ ->
                                    Touched (parse model.value)
                      }
                    , Cmd.none
                    )

                Text_DebounceStarted now ->
                    ( { model | status = Debouncing now }
                    , Task.perform (\() -> Text_DebounceChecked now) (Process.sleep 500)
                    )

                Text_DebounceChecked now ->
                    ( case model.status of
                        Debouncing current ->
                            if now == current then
                                { model | status = Touched (parse model.value) }

                            else
                                model

                        _ ->
                            model
                    , Cmd.none
                    )
    , subscriptions =
        \_ ->
            Sub.none
    }


textInputView label { value, status } errs =
    let
        ( icon, message ) =
            viewFeedback label status errs
    in
    Html.div []
        [ Html.label []
            [ Html.strong [] [ Html.text label ]
            , Html.div []
                [ Html.input
                    [ Html.Events.onInput Text_Changed
                    , Html.Events.onBlur Text_Touched
                    , Html.Attributes.value value
                    ]
                    []
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]



-- SELECT INPUT


type SelectInputMsg a
    = Select_Selected (Maybe a)
    | Select_Filtered String
    | Select_Touched
    | Select_Reset


select label =
    let
        parse selected =
            Touched (Result.fromMaybe [ ( label, "Must select an option" ) ] selected)

        init =
            ( { value = { selected = Nothing, filter = "" }, status = Intact }, Cmd.none )
    in
    { interface =
        \toSelf model ->
            { view =
                \{ toId, toHtml, toString, items, errors } ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.status errors

                        filtered =
                            if String.isEmpty model.value.filter then
                                items

                            else
                                List.filter
                                    (\item ->
                                        String.contains
                                            (String.toLower model.value.filter)
                                            (String.toLower (toString item))
                                    )
                                    items
                    in
                    Html.div []
                        [ Html.strong []
                            [ Html.text label ]
                        , Html.div []
                            [ Html.span []
                                [ Html.text "Filter"
                                , Html.input
                                    [ Html.Attributes.type_ "search"
                                    , Html.Events.onInput (toSelf << Select_Filtered)
                                    , Html.Attributes.value model.value.filter
                                    ]
                                    []
                                , Html.button
                                    [ Html.Attributes.type_ "button"
                                    , Html.Events.onClick (toSelf (Select_Filtered ""))
                                    ]
                                    [ Html.text "x" ]
                                ]
                            , Html.div []
                                (case filtered of
                                    [] ->
                                        [ Html.text "[no options]" ]

                                    _ ->
                                        List.map
                                            (\item ->
                                                let
                                                    id =
                                                        toId item

                                                    isChecked =
                                                        model.value.selected == Just id
                                                in
                                                Html.div []
                                                    [ Html.label []
                                                        [ Html.input
                                                            [ Html.Attributes.type_ "radio"
                                                            , Html.Attributes.name (label ++ "-radio")
                                                            , Html.Attributes.checked isChecked
                                                            , Html.Events.onCheck
                                                                (\nowChecked ->
                                                                    toSelf
                                                                        (Select_Selected
                                                                            (if nowChecked then
                                                                                Just id

                                                                             else
                                                                                Nothing
                                                                            )
                                                                        )
                                                                )
                                                            , Html.Events.onBlur (toSelf Select_Touched)
                                                            ]
                                                            []
                                                        , toHtml item
                                                        ]
                                                    ]
                                            )
                                            filtered
                                )
                            ]
                        , Html.text icon
                        , Html.small [] [ Html.text message ]
                        ]
            , selected = model.value.selected
            , parsed = model.status
            , reset = toSelf Select_Reset
            , touch = toSelf Select_Touched
            }
    , init =
        \_ _ ->
            init
    , update =
        \app_ _ msg model ->
            case msg of
                Select_Filtered filter ->
                    let
                        value =
                            model.value
                    in
                    ( { model
                        | value =
                            { value
                                | filter = filter
                                , selected = Nothing
                            }
                        , status = parse Nothing
                      }
                    , send (app_.selectionUpdated Nothing)
                    )

                Select_Selected selection ->
                    let
                        value =
                            model.value
                    in
                    ( { model | value = { value | selected = selection }, status = parse selection }
                    , send (app_.selectionUpdated selection)
                    )

                Select_Touched ->
                    ( { model | status = parse model.value.selected }, Cmd.none )

                Select_Reset ->
                    init
    , subscriptions =
        \_ _ _ ->
            Sub.none
    }



-- BOOLEAN INPUT


type BoolInputMsg
    = Bool_Changed Bool
    | Bool_Touched


bool label =
    { interface =
        \toSelf model ->
            { view =
                \errs ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.status errs
                    in
                    Html.div []
                        [ Html.label []
                            [ Html.strong [] [ Html.text label ]
                            , Html.input
                                [ Html.Attributes.type_ "checkbox"
                                , Html.Attributes.checked model.value
                                , Html.Events.onCheck (\_ -> toSelf (Bool_Changed (not model.value)))
                                , Html.Events.onBlur (toSelf Bool_Touched)
                                ]
                                []
                            ]
                        , Html.text icon
                        , Html.small [] [ Html.text message ]
                        ]
            , parsed = model.status
            , reset = toSelf (Bool_Changed False)
            , touch = toSelf Bool_Touched
            }
    , init =
        \_ ->
            ( { value = True, status = Intact }, Cmd.none )
    , update =
        \msg model ->
            case msg of
                Bool_Changed b ->
                    ( { value = b, status = Touched (Ok b) }, Cmd.none )

                Bool_Touched ->
                    ( { model | status = Touched (Ok model.value) }, Cmd.none )
    , subscriptions =
        \_ ->
            Sub.none
    }



-- INPUT VIEW HELPERS


viewFeedback label status errs =
    let
        relevantErrs =
            errs
                |> List.filterMap
                    (\( key, val ) ->
                        if key == label then
                            Just val

                        else
                            Nothing
                    )
    in
    case status of
        Intact ->
            ( "", "" )

        Touched _ ->
            case relevantErrs of
                [] ->
                    ( " ✅", "" )

                _ ->
                    ( " 🚫"
                    , String.join "\n" relevantErrs
                    )

        Debouncing _ ->
            ( " ⌨️", "" )
