module DnD exposing (main)

import Browser
import Browser.Navigation
import Composer.Application
import DnDList
import Html
import Html.Attributes
import Process
import Task
import Url


type alias Flags =
    ()


type alias ProgModel =
    ( AppModel, ( DnDModel, () ) )


type alias ProgMsg =
    ( Maybe AppMsg, ( Maybe DnDMsg, () ) )


type alias Components =
    { dnd : DnDInterface }


type alias AppModel =
    { fruits : List String, key : Browser.Navigation.Key }


type AppMsg
    = ItemsUpdated (List String)
    | UrlRequested Browser.UrlRequest
    | UrlChanged Url.Url


type alias AppInterface =
    { items : List String
    , itemsUpdated : List String -> ProgMsg
    }


type alias DnDModel =
    { dnd : DnDList.Model }


type DnDMsg
    = DnDMsg DnDList.Msg


type alias DnDInterface =
    { view : List String -> Html.Html ProgMsg }


fruits : List String
fruits =
    [ "Apples", "Bananas", "Cherries", "Dates" ]


main :
    Program
        ()
        ProgModel
        ProgMsg
main =
    Composer.Application.app app_
        |> Composer.Application.component
            dndList
            (\toApp appModel ->
                { items = appModel.fruits
                , itemsUpdated = toApp << ItemsUpdated
                }
            )
        |> Composer.Application.compose (\dnd -> { dnd = dnd })
        |> Browser.application


app_ :
    { init : Components -> (AppMsg -> ProgMsg) -> Flags -> Url.Url -> Browser.Navigation.Key -> ( AppModel, Cmd ProgMsg )
    , view : Components -> (AppMsg -> ProgMsg) -> AppModel -> Browser.Document ProgMsg
    , update : Components -> (AppMsg -> ProgMsg) -> AppMsg -> AppModel -> ( AppModel, Cmd ProgMsg )
    , subscriptions : Components -> (AppMsg -> ProgMsg) -> AppModel -> Sub ProgMsg
    , onUrlRequest : Browser.UrlRequest -> AppMsg
    , onUrlChange : Url.Url -> AppMsg
    }
app_ =
    { init =
        \components toSelf flags url key ->
            ( { fruits = fruits, key = key }, Cmd.none )
    , update =
        \components toSelf msg model ->
            case msg of
                ItemsUpdated fruits_ ->
                    ( { model | fruits = fruits_ }, Cmd.none )

                UrlRequested _ ->
                    ( model, Cmd.none )

                UrlChanged _ ->
                    ( model, Cmd.none )
    , view =
        \components toSelf model ->
            { title = "Drag and drop demo"
            , body =
                [ Html.div []
                    [ Html.p [] [ Html.text "This is the view of the `dndList` component:" ]
                    , components.dnd.view model.fruits
                    , Html.p [] [ Html.text "This is a `Debug.toString` of the list of items:" ]
                    , Html.text (Debug.toString model.fruits)
                    ]
                ]
            }
    , subscriptions =
        \components toSelf model -> Sub.none
    , onUrlRequest = UrlRequested
    , onUrlChange = UrlChanged
    }


dndList :
    { interface : (DnDMsg -> ProgMsg) -> DnDModel -> DnDInterface
    , init : (DnDMsg -> ProgMsg) -> Flags -> ( DnDModel, Cmd ProgMsg )
    , update : AppInterface -> (DnDMsg -> ProgMsg) -> DnDMsg -> DnDModel -> ( DnDModel, Cmd ProgMsg )
    , subscriptions : AppInterface -> (DnDMsg -> ProgMsg) -> DnDModel -> Sub ProgMsg
    }
dndList =
    { interface =
        \toSelf model ->
            { view = view toSelf model }
    , init =
        \toSelf flags ->
            ( { dnd = system.model }
            , Cmd.none
            )
    , update =
        \app toSelf msg model ->
            case msg of
                DnDMsg dndMsg ->
                    let
                        ( dnd, newItems ) =
                            system.update dndMsg model.dnd app.items
                    in
                    ( { model | dnd = dnd }
                    , Cmd.batch
                        [ send (app.itemsUpdated newItems)
                        , Cmd.map toSelf (system.commands dnd)
                        ]
                    )
    , subscriptions =
        \app toSelf model ->
            subscriptions model
                |> Sub.map toSelf
    }


send msg =
    Task.perform identity (Task.succeed msg)


config : DnDList.Config String
config =
    { beforeUpdate = \_ _ list -> list
    , movement = DnDList.Free
    , listen = DnDList.OnDrag
    , operation = DnDList.Rotate
    }


system : DnDList.System String DnDMsg
system =
    DnDList.create config DnDMsg


subscriptions : DnDModel -> Sub DnDMsg
subscriptions model =
    system.subscriptions model.dnd


view toSelf model items =
    Html.section
        [ Html.Attributes.style "text-align" "center" ]
        [ items
            |> List.indexedMap (itemView model.dnd)
            |> Html.div []
        , ghostView model.dnd items
        ]
        |> Html.map toSelf


itemView : DnDList.Model -> Int -> String -> Html.Html DnDMsg
itemView dnd index item =
    let
        itemId : String
        itemId =
            "id-" ++ item
    in
    case system.info dnd of
        Just { dragIndex } ->
            if dragIndex /= index then
                Html.p
                    (Html.Attributes.id itemId :: system.dropEvents index itemId)
                    [ Html.text item ]

            else
                Html.p
                    [ Html.Attributes.id itemId ]
                    [ Html.text "[---------]" ]

        Nothing ->
            Html.p
                (Html.Attributes.id itemId :: system.dragEvents index itemId)
                [ Html.text item ]


ghostView : DnDList.Model -> List String -> Html.Html DnDMsg
ghostView dnd items =
    let
        maybeDragItem : Maybe String
        maybeDragItem =
            system.info dnd
                |> Maybe.andThen (\{ dragIndex } -> items |> List.drop dragIndex |> List.head)
    in
    case maybeDragItem of
        Just item ->
            Html.div
                (system.ghostStyles dnd)
                [ Html.text item ]

        Nothing ->
            Html.text ""
