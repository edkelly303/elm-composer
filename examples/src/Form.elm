module Form exposing (main)

import Browser
import Composer.Element
import Html
import Html.Attributes
import Html.Events
import Http
import Process
import Task
import Time


main : Program () ProgModel ProgMsg
main =
    Browser.element
        { init =
            \_ ->
                form.init ()
                    |> Tuple.mapSecond (Cmd.map FormMsg)
        , update =
            \msg model ->
                case msg of
                    ToysLoaded (Ok toys) ->
                        let
                            ( appModel, restModels ) =
                                model
                        in
                        ( ( { appModel | toys = toys }, restModels )
                        , Cmd.none
                        )

                    ToysLoaded (Err e) ->
                        let
                            _ =
                                Debug.log "request failed" e
                        in
                        ( model
                        , Cmd.none
                        )

                    FormMsg formMsg ->
                        let
                            requestToys =
                                case formMsg of
                                    ( Just (PetUpdated (Just petId)), _ ) ->
                                        Http.get
                                            { expect =
                                                Http.expectString
                                                    (\_ ->
                                                        ToysLoaded (Ok (List.filter (\toy -> toy.petId == petId) petToys))
                                                    )
                                            , url = "http://localhost:8000/clock.html"
                                            }

                                    _ ->
                                        Cmd.none

                            ( formModel, formCmd ) =
                                form.update formMsg model
                        in
                        ( formModel
                        , Cmd.batch
                            [ requestToys
                            , Cmd.map FormMsg formCmd
                            ]
                        )
        , view = form.view >> Html.map FormMsg
        , subscriptions = form.subscriptions >> Sub.map FormMsg
        }


type ProgMsg
    = FormMsg FormMsg
    | ToysLoaded (Result Http.Error (List PetToy))


type alias ProgModel =
    ( AppModel
    , ( { status : InputStatus String, value : String }
      , ( { status : InputStatus Int, value : String }
        , ( Bool
          , ( { status : InputStatus Int, value : Maybe Int }
            , ( { status : InputStatus Int, value : Maybe Int }
              , ()
              )
            )
          )
        )
      )
    )


type alias User =
    { name : String, age : Int, cool : Bool, petId : Int, toyId : Int }


type alias Pet =
    { name : String, id : Int }


pets : List Pet
pets =
    [ { id = 1, name = "Fido" }
    , { id = 2, name = "Miaowcus" }
    ]


type alias PetToy =
    { id : Int, name : String, petId : Int }


petToys : List PetToy
petToys =
    [ { id = 1, name = "ball of string", petId = 2 }
    , { id = 2, name = "scratching post", petId = 2 }
    , { id = 3, name = "bone", petId = 1 }
    , { id = 4, name = "fluffy penguin", petId = 1 }
    ]


type alias FormMsg =
    ( Maybe AppMsg
    , ( Maybe TextInputMsg
      , ( Maybe TextInputMsg
        , ( Maybe Bool
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
    Composer.Element.integrate formApp
        |> Composer.Element.withSimpleComponent (string "Name")
        |> Composer.Element.withSimpleComponent (int "Age")
        |> Composer.Element.withSimpleComponent (bool "Is cool?")
        |> Composer.Element.withComponent
            (select "Pet")
            (\toApp _ -> { selectionUpdated = \maybePetId -> toApp (PetUpdated maybePetId) })
        |> Composer.Element.withComponent
            (select "Toy")
            (\toApp _ -> { selectionUpdated = \maybeToyId -> toApp (ToyUpdated maybeToyId) })
        |> Composer.Element.groupedAs
            (\name age cool pet toy ->
                { name = name
                , age = age
                , cool = cool
                , pet = pet
                , toy = toy
                }
            )


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

        ( _, _ ) ->
            Touched (Err [])


type AppMsg
    = SubmitClicked
    | BackClicked
    | PetUpdated (Maybe Int)
    | ToyUpdated (Maybe Int)


type alias AppModel =
    { page : AppPage
    , pets : List Pet
    , toys : List PetToy
    }


type AppPage
    = FormActive
    | Success User


formApp =
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
            ( { page = FormActive, pets = pets, toys = [] }, Cmd.none )
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
        \{ name, age, cool, pet, toy } toSelf model ->
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
                            , items = model.pets
                            , errors = errors
                            }
                        , toy.view
                            { toId = .id
                            , toHtml = .name >> Html.text
                            , items = model.toys
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


type TextInputMsg
    = StringChanged String
    | Touch
    | Reset
    | DebounceStarted Time.Posix
    | DebounceChecked Time.Posix


type InputStatus parsed
    = Intact
    | Debouncing Time.Posix
    | Touched (Result (List ( String, String )) parsed)


type SelectInputMsg a
    = Select_Selected (Maybe a)
    | Select_Touch
    | Select_Reset


select label =
    let
        parse selected =
            Touched (Result.fromMaybe [ ( label, "Must select an option" ) ] selected)

        init =
            ( { value = Nothing, status = Intact }, Cmd.none )
    in
    { interface =
        \toSelf model ->
            { view =
                \{ toId, toHtml, items, errors } ->
                    let
                        ( icon, message ) =
                            viewFeedback label model.status errors
                    in
                    Html.div []
                        [ Html.strong []
                            [ Html.text label ]
                        , Html.div []
                            [ Html.span []
                                (List.map
                                    (\item ->
                                        let
                                            id =
                                                toId item

                                            isChecked =
                                                model.value == Just id
                                        in
                                        Html.label []
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
                                                ]
                                                []
                                            , toHtml item
                                            ]
                                    )
                                    items
                                )
                            , Html.text icon
                            ]
                        , Html.small [] [ Html.text message ]
                        ]
            , selected = model.value
            , parsed = model.status
            , reset = toSelf Select_Reset
            , touch = toSelf Select_Touch
            }
    , init =
        \_ _ ->
            init
    , update =
        \app _ msg model ->
            case msg of
                Select_Selected selection ->
                    ( { model | value = selection, status = parse selection }
                    , send (app.selectionUpdated selection)
                    )

                Select_Touch ->
                    ( { model | status = parse model.value }, Cmd.none )

                Select_Reset ->
                    init
    , subscriptions =
        \_ _ _ ->
            Sub.none
    }


bool label =
    { interface =
        \toSelf model ->
            let
                parse m =
                    Touched (Ok m)
            in
            { view =
                \errs ->
                    let
                        ( _, message ) =
                            viewFeedback label (parse model) errs
                    in
                    Html.div []
                        [ Html.label []
                            [ Html.strong [] [ Html.text label ]
                            , Html.input
                                [ Html.Attributes.type_ "checkbox"
                                , Html.Attributes.checked model
                                , Html.Events.onCheck (\_ -> toSelf (not model))
                                ]
                                []
                            ]
                        , Html.small [] [ Html.text message ]
                        ]
            , parsed = parse model
            , reset = toSelf False
            }
    , init =
        \_ ->
            ( False, Cmd.none )
    , update =
        \msg _ ->
            ( msg, Cmd.none )
    , subscriptions =
        \_ ->
            Sub.none
    }


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
            , touch = toSelf Touch
            , reset = toSelf Reset
            }
    , init =
        \_ ->
            init
    , update =
        \msg model ->
            case msg of
                StringChanged str ->
                    ( { model | value = str }
                    , Task.perform DebounceStarted Time.now
                    )

                Reset ->
                    init

                Touch ->
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

                DebounceStarted now ->
                    ( { model | status = Debouncing now }
                    , Task.perform (\() -> DebounceChecked now) (Process.sleep 500)
                    )

                DebounceChecked now ->
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
                    [ Html.Events.onInput StringChanged
                    , Html.Attributes.value value
                    ]
                    []
                , Html.text icon
                ]
            , Html.small [] [ Html.text message ]
            ]
        ]


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
