module Form exposing (main)

import Browser
import Composer.Element exposing (..)
import Date
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
    , dateOfBirth : Date.Date
    , height : Int
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
    , { id = 2, name = "Kitty" }
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
      , ( InputModel String Date.Date
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
    )


type alias FormMsg =
    ( Maybe AppMsg
    , ( Maybe TextInputMsg
      , ( Maybe DateInputMsg
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
    )


form =
    defineForm app
        (\name dateOfBirth height cool pet toy ->
            { name = name
            , dateOfBirth = dateOfBirth
            , height = height
            , cool = cool
            , pet = pet
            , toy = toy
            }
        )
        |> withField "Name" string
        |> withField "Date of birth" date
        |> withField "Height" int
        |> withField "Is cool?" bool
        |> withSelectAndNotify "Pet" PetUpdated
        |> withSelect "Toy"
        |> endForm


defineForm shared grouper =
    { fields = integrate shared
    , grouper = grouper
    }


withField label field builder =
    { fields =
        builder.fields
            |> withSimpleComponent (field label)
    , grouper = builder.grouper
    }


withSelect label builder =
    { fields =
        builder.fields
            |> withComponent
                (select label)
                (\_ _ -> { selectionUpdated = Nothing })
    , grouper = builder.grouper
    }


withSelectAndNotify label msg builder =
    { fields =
        builder.fields
            |> withComponent
                (select label)
                (\toApp _ ->
                    { selectionUpdated =
                        Just
                            (\maybeSelection ->
                                toApp (msg maybeSelection)
                            )
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


type alias AppModel =
    { page : AppPage }


type AppPage
    = FormActive
    | Success User


validate name dateOfBirth height cool pet toy =
    succeed
        (\name_ dateOfBirth_ { height_, cool_ } pet_ toy_ ->
            User name_ dateOfBirth_ height_ cool_ pet_ toy_
        )
        |> check name.parsed
        |> check dateOfBirth.parsed
        |> check
            (multi2
                (\height_ cool_ ->
                    if cool_ && height_ > 180 then
                        Just
                            { height_ = height_
                            , cool_ = cool_
                            }

                    else
                        Nothing
                )
                height.parsed
                cool.parsed
            )
        |> check pet.parsed
        |> check toy.parsed


app =
    { init =
        \_ _ () ->
            ( { page = FormActive }, Cmd.none )
    , update =
        \{ name, dateOfBirth, height, cool, pet, toy } _ msg model ->
            case msg of
                SubmitClicked ->
                    case validate name dateOfBirth height cool pet toy of
                        Ok user ->
                            ( { model | page = Success user }
                            , Cmd.batch
                                [ send name.reset
                                , send dateOfBirth.reset
                                , send height.reset
                                , send cool.reset
                                , send pet.reset
                                , send toy.reset
                                ]
                            )

                        Err _ ->
                            ( { model | page = FormActive }
                            , Cmd.batch
                                [ send name.touch
                                , send dateOfBirth.touch
                                , send height.touch
                                , send cool.touch
                                , send pet.touch
                                , send toy.touch
                                ]
                            )

                BackClicked ->
                    ( { model | page = FormActive }
                    , Cmd.none
                    )

                PetUpdated _ ->
                    ( model, send toy.reset )
    , view =
        \{ name, dateOfBirth, height, cool, pet, toy } toSelf model toys ->
            case model.page of
                FormActive ->
                    let
                        errors =
                            case validate name dateOfBirth height cool pet toy of
                                Err errs_ ->
                                    errs_

                                Ok _ ->
                                    []
                    in
                    Html.form []
                        [ Html.h1 [] [ Html.text "Create a user" ]
                        , name.view errors
                        , dateOfBirth.view errors
                        , height.view errors
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


check parsed resCtor =
    case ( parsed.status, resCtor ) of
        ( Touched (Just arg), Ok ctor ) ->
            Ok (ctor arg)

        ( Touched (Just _), Err errs ) ->
            Err errs

        ( Touched Nothing, Ok _ ) ->
            Err []

        ( Touched Nothing, Err errs2 ) ->
            Err errs2

        ( _, Err errs ) ->
            Err errs

        ( _, Ok _ ) ->
            Err []


multi2 f parsed1 parsed2 =
    let
        newParsed =
            { status = Intact, feedback = parsed1.feedback ++ parsed2.feedback }
    in
    { newParsed
        | status =
            case ( parsed1.status, parsed2.status ) of
                ( Touched (Just arg1), Touched (Just arg2) ) ->
                    Touched (f arg1 arg2)

                _ ->
                    Touched Nothing
    }



-- COMPONENT TYPES & DEFINITIONS


type alias InputModel value parsed =
    { parsed :
        { status : InputStatus parsed
        , feedback : List { message : String, outcome : Outcome }
        }
    , value : value
    }


type InputStatus parsed
    = Intact
    | Debouncing Time.Posix
    | Touched (Maybe parsed)


type Outcome
    = Pass
    | Fail
    | Warn



-- TEXT INPUTS


type TextInputMsg
    = Text_Changed String
    | Text_Touched
    | Text_Reset
    | Text_DebounceStarted Time.Posix
    | Text_DebounceChecked Time.Posix


string label =
    textInput
        (\value ->
            if String.isEmpty value then
                { status = Touched Nothing
                , feedback = [ { message = label ++ " must not be blank ", outcome = Fail } ]
                }

            else
                { status = Touched (Just value)
                , feedback = [ { message = label ++ " must not be blank ", outcome = Pass } ]
                }
        )
        label


int label =
    textInput
        (\value ->
            case String.toInt value of
                Just i ->
                    { status = Touched (Just i)
                    , feedback = [ { message = label ++ " must be an integer", outcome = Pass } ]
                    }

                Nothing ->
                    { status = Touched Nothing
                    , feedback = [ { message = label ++ " must be an integer", outcome = Fail } ]
                    }
        )
        label


textInput parse label =
    let
        init =
            ( { value = ""
              , parsed = { status = Intact, feedback = [] }
              }
            , Cmd.none
            )
    in
    { interface =
        \toSelf model ->
            { view = \errs -> textInputView label model errs |> Html.map toSelf
            , parsed = model.parsed
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
                    ( case model.parsed.status of
                        Touched _ ->
                            model

                        _ ->
                            { model | parsed = parse model.value }
                    , Cmd.none
                    )

                Text_DebounceStarted now ->
                    let
                        parsed =
                            model.parsed
                    in
                    ( { model | parsed = { parsed | status = Debouncing now } }
                    , Task.perform (\() -> Text_DebounceChecked now) (Process.sleep 500)
                    )

                Text_DebounceChecked now ->
                    ( case model.parsed.status of
                        Debouncing current ->
                            if now == current then
                                { model | parsed = parse model.value }

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


textInputView label { value, parsed } errs =
    let
        ( icon, message ) =
            viewFeedback label parsed errs
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



-- DATE INPUT


type DateInputMsg
    = Date_Changed String
    | Date_Touched


date label =
    { init =
        \flags ->
            ( { value = "", parsed = { status = Intact, feedback = [] } }
            , Task.perform (\now -> Date_Changed (Date.toIsoString (Date.fromPosix Time.utc now))) Time.now
            )
    , interface =
        \toSelf model ->
            { view =
                \errors ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.parsed errors
                    in
                    Html.div []
                        [ Html.strong [] [ Html.text label ]
                        , Html.div []
                            [ Html.input
                                [ Html.Attributes.type_ "date"
                                , Html.Attributes.value model.value
                                , Html.Events.onInput (toSelf << Date_Changed)
                                ]
                                []
                            ]
                        , Html.text icon
                        , Html.small [] [ Html.text message ]
                        ]
            , parsed = model.parsed
            , touch = toSelf Date_Touched
            , reset = toSelf (Date_Changed "")
            }
    , update =
        \msg model ->
            let
                parse str =
                    case Date.fromIsoString str of
                        Ok date_ ->
                            { status = Touched (Just date_)
                            , feedback = []
                            }

                        Err e ->
                            { status = Touched Nothing
                            , feedback = []
                            }
            in
            case msg of
                Date_Touched ->
                    ( { model | parsed = parse model.value }
                    , Cmd.none
                    )

                Date_Changed str ->
                    ( { model
                        | value = str
                        , parsed = parse str
                      }
                    , Cmd.none
                    )
    , subscriptions =
        \model ->
            Sub.none
    }



-- SELECT INPUT


type SelectInputMsg a
    = Select_Selected (Maybe a)
    | Select_Filtered String
    | Select_Touched
    | Select_Reset


select label =
    let
        parse selected =
            { status = Touched selected
            , feedback =
                [ { message = "Must select an option"
                  , outcome =
                        case selected of
                            Nothing ->
                                Fail

                            Just _ ->
                                Pass
                  }
                ]
            }

        init =
            ( { value = { selected = Nothing, filter = "" }
              , parsed = { status = Intact, feedback = [] }
              }
            , Cmd.none
            )
    in
    { interface =
        \toSelf model ->
            { view =
                \{ toId, toHtml, toString, items, errors } ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.parsed errors

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
            , parsed = model.parsed
            , reset = toSelf Select_Reset
            , touch = toSelf Select_Touched
            }
    , init =
        \_ _ ->
            init
    , update =
        \app_ _ msg model ->
            let
                notify maybe =
                    case app_.selectionUpdated of
                        Nothing ->
                            Cmd.none

                        Just f ->
                            send (f maybe)
            in
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
                        , parsed = parse Nothing
                      }
                    , notify Nothing
                    )

                Select_Selected selection ->
                    let
                        value =
                            model.value
                    in
                    ( { model | value = { value | selected = selection }, parsed = parse selection }
                    , notify selection
                    )

                Select_Touched ->
                    ( { model | parsed = parse model.value.selected }
                    , Cmd.none
                    )

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
                            viewFeedback label model.parsed errs
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
            , parsed = model.parsed
            , reset = toSelf (Bool_Changed False)
            , touch = toSelf Bool_Touched
            }
    , init =
        \_ ->
            ( { value = True, parsed = { status = Intact, feedback = [] } }
            , Cmd.none
            )
    , update =
        \msg model ->
            case msg of
                Bool_Changed b ->
                    ( { value = b
                      , parsed = { status = Touched (Just b), feedback = [] }
                      }
                    , Cmd.none
                    )

                Bool_Touched ->
                    ( { model
                        | parsed = { status = Touched (Just model.value), feedback = [] }
                      }
                    , Cmd.none
                    )
    , subscriptions =
        \_ ->
            Sub.none
    }



-- INPUT VIEW HELPERS


viewFeedback label parsed errs =
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
    case parsed.status of
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
