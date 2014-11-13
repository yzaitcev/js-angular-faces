mosFaces = angular.module 'mosFaces', [
    'mosRsrs.faces'
    'mosDtvs.fileModel'
    'mosDtvs.infiniteScroll'
    'mosSvcs.unsavedChanges'
    'ui.bootstrap'
    'ui.sortable'
]

mosFaces.controller 'mosFaces.ctrlAdd', ['$scope', '$routeParams', '$modal', '$location', 'rsrProject', 'rsrFace', 'unsavedChanges', ($scope, $routeParams, $modal, $location, rsrProject, rsrFace, unsavedChanges) ->
    $scope.sProjectId = $routeParams.project

    # Form state
    $scope.sFormState = 'default'

    # Face object
    $scope.oFace = new rsrFace

    # Listen the changes of oFace in the current scope
    # User will be prompted if he tries to leave the page without saving the changes
    unsavedChanges.fnListen $scope, $scope.oFace

    # OPTIONS of POST request. It contains choices for the Origin dropdown
    $scope.oPostOptions = rsrFace.queryPostOptions {project: $scope.sProjectId}

    # Submit form handler
    $scope.fnSubmit = () ->
        # Prevent saving request if form is invalid
        return if $scope.oForm.$invalid

        $scope.sFormState = 'sending'
        $scope.oFace.$save 
            project: $routeParams.project
        ,()->
            alert 'Success!'
            unsavedChanges.fnRemoveListener()
            $location.path "/faces/#{$scope.sProjectId}"
        , () ->
            alert 'Error!'
        .finally () ->
            $scope.sFormState = 'default'
]

mosFaces.controller 'mosFaces.ctrlEdit', ['$scope', '$routeParams', '$modal', '$location', 'rsrProject', 'rsrFace', 'unsavedChanges', ($scope, $routeParams, $modal, $location, rsrProject, rsrFace, unsavedChanges) ->
    $scope.sProjectId = $routeParams.project

    # Form state
    $scope.sFormState = 'default'

    # Get Face
    $scope.oFace = rsrFace.get {face: $routeParams.face}, ->
        # Listen the changes of oFace in the current scope
        # User will be prompted if he tries to leave the page without saving the changes
        unsavedChanges.fnListen $scope, $scope.oFace

    # OPTIONS of PUT request. It contains choices for the Origin dropdown
    $scope.oPutOptions = rsrFace.queryPutOptions()

    # Submit form handler
    $scope.fnSubmit = () ->
        # Prevent saving request if form is invalid
        return if $scope.oForm.$invalid

        $scope.sFormState = 'sending'
        $scope.oFace.$update ()->
            alert 'Success!'
            unsavedChanges.fnRemoveListener()
            $location.path "/faces/#{$scope.sProjectId}"
        , () ->
            alert 'Error!'
        .finally () ->
            $scope.sFormState = 'default'

    # Delete face
    $scope.fnDelete = () ->
        # Prevent unintentional delete
        return if not confirm 'Are you sure you want to delete this model?'

        $scope.sFormState = 'sending'
        $scope.oFace.$delete () ->
            alert 'Deleted!'
            unsavedChanges.fnRemoveListener()
            $location.path "/faces/#{$scope.sProjectId}"
        , () ->
            alert 'Error!'
        .finally () ->
            $scope.sFormState = 'default'
]

# Display list of all available faces and allow user to select/reorder it by dragging (ui-sortable)
mosFaces.controller 'mosFaces.ctrlList', ['$scope', '$routeParams', 'rsrProject', 'rsrFace', 'unsavedChanges', ($scope, $routeParams, rsrProject, rsrFace, unsavedChanges) ->
    $scope.oProject = rsrProject.get {project: $routeParams.project}

    # Form state
    $scope.sFormState = 'default'

    # Faces lists: active and all
    $scope.oaFaces = 
        active: []
        all: []

    # Get the active faces
    $scope.oaFaces.active = rsrFace.queryActive {project: $routeParams.project}, ->
        # Listen the changes of Active Faces array
        # User will be prompted if he tries to leave the page without saving the changes
        unsavedChanges.fnListen $scope, $scope.oaFaces.active

    # Load-more button: presets & methods
    $scope.oBtnLoadMore =
        disabled: true
        text: 'Loading...'
        visible: false
        enable: ->
            @disabled = false
            @text = 'Load more'
        disable: ->
            @disabled = true
            @text = 'Loading...'
        hide: -> @visible = false
        show: -> @visible = true

    # Face resource wrapper
    $scope.oPaginator =
        # Number of all hairs
        iCount: 0
        # Number of next page to load
        pageNum: 1
        # Make query and return resource example object
        makeQuery: ->
            # Get the page of available faces
            oPage = rsrFace.queryPage
                project: $routeParams.project
                page: @pageNum
            , =>
                @iCount = oPage.count
                @pageNum++

    # Method to pass to infinite-scroll directive
    $scope.fnLoadMoreFaces = () ->
        # If first query is missed || promise is resolved && next page exists
        if not $scope.oQueriedPage? or $scope.oQueriedPage.$resolved and $scope.oQueriedPage.next
            $scope.oBtnLoadMore.disable()
            # Return resource example and save it to variable
            $scope.oQueriedPage = $scope.oPaginator.makeQuery()
             # Add callbacks to resource example promise
            $scope.oQueriedPage.$promise.then(
                (oPage)->
                    # Concat the arras in loop since concat method can fail for big amount of data
                    for oFace in oPage.results
                        $scope.oaFaces.all.push oFace

                    if not oPage.next
                        $scope.oBtnLoadMore.hide()
                    else 
                        $scope.oBtnLoadMore.show()
            ,
                () -> alert 'Error!'
            ).finally -> $scope.oBtnLoadMore.enable()

    # Make first query
    $scope.fnLoadMoreFaces()

    # Get more
    # Check if face is selected. Return index or boolean depends on second argument
    $scope.fnIsSelected = (oFace, bReturnIndex = false)->
        iFoundIndex = fnIndexOfFace $scope.oaFaces.active, oFace
        
        # Return index
        return iFoundIndex if bReturnIndex is true

        # Return boolean value
        if iFoundIndex isnt -1 then true else false
       
    # Choose/Unchoose the face
    $scope.fnSelect = (oFace)->
        # Search the index of face if it's already selected
        iFoundIndex = $scope.fnIsSelected oFace, true

        # Select or unselect face
        if iFoundIndex is -1
            $scope.oaFaces.active.push oFace
        else
            $scope.oaFaces.active.splice iFoundIndex, 1

    # Clear selected faces. It means empty active faces list
    $scope.fnClearSelection = ()->
        $scope.oaFaces.active.length = 0

    # Save new list of active faces
    $scope.fnSave = ()->
        # Empty active_faces array
        $scope.oProject.active_faces.length = 0

        # Populate active_faces with new array
        $scope.oProject.active_faces = (oFace.id for oFace in $scope.oaFaces.active)

        $scope.sFormState = 'sending'
        $scope.oProject.$update ()->
            alert 'Saved!'
        , () ->
            alert 'Error!'
        .finally () ->
            $scope.sFormState = 'default'
            # Reset unsavedChanges listener when user saved the changes
            unsavedChanges.fnListen $scope, $scope.oaFaces.active
]

# Module routes
mosFaces.config ['$routeProvider', ($routeProvider) ->
    $routeProvider
        # List of faces
        .when '/faces/:project',
            title       : 'Model Selection',
            templateUrl : 'app/modules/faces/views/list.html',
            controller  : 'mosFaces.ctrlList'
        # Add face
        .when '/faces/:project/add',
            title       : 'Add Model'
            templateUrl : 'app/modules/faces/views/add.html'
            controller  : 'mosFaces.ctrlAdd'
        # Edit face
        .when '/faces/:project/edit/:face',
            title       : 'Edit Model'
            templateUrl : 'app/modules/faces/views/edit.html'
            controller  : 'mosFaces.ctrlEdit'
]

# Searching the index of Face in array
# Return -1 if face not found in array, index otherwise (similar to indexOf)
fnIndexOfFace = (aArray, oFace)->
    aFound = (i for oActiveFace, i in aArray when oActiveFace.id is oFace.id)
    if aFound.length > 0 then aFound[0] else -1
