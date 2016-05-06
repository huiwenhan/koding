_ = require 'lodash'
kd = require 'kd'
AppController = require 'app/appcontroller'
StackEditorView = require './editor'
showError = require 'app/util/showError'
OnboardingView = require 'stacks/views/stacks/onboarding/onboardingview'
EnvironmentFlux = require 'app/flux/environment'

do require './routehandler'

module.exports = class StackEditorAppController extends AppController

  @options     =
    name       : 'Stackeditor'
    behavior   : 'application'


  openEditor: (stackTemplateId) ->

    { computeController } = kd.singletons

    @mainView.destroySubViews()

    if stackTemplateId
      computeController.fetchStackTemplate stackTemplateId, (err, stackTemplate) =>
        return showError err  if err
        @createView stackTemplate
    else
      @createView()


  openStackWizard: ->

    @openEditor()

    modal = new kd.ModalView
      width : 820

    view = new OnboardingView

    createOnce = do (isCreated = no) -> (overrides = {}) ->
      return  if isCreated
      isCreated = yes
      EnvironmentFlux.actions.createStackTemplateWithDefaults overrides
        .then ({ stackTemplate }) ->
          kd.singletons.router.handleRoute "/Stack-Editor/#{stackTemplate._id}"

    view.on 'StackOnboardingCompleted', (result) ->
      overrides = {}

      if result?.template
        overrides = _.assign overrides, { template: result.template.content }

      if result?.selectedProvider
        overrides = _.assign overrides, { selectedProvider: result.selectedProvider }

      createOnce overrides
      modal.destroy()

    modal.addSubView view

    modal.on 'KDObjectWillBeDestroyed', createOnce


  createView: (stackTemplate) ->

    options = { skipFullscreen : yes }
    data    = { stackTemplate, showHelpContent : yes }
    view    = new StackEditorView options, data
    view.on 'Cancel', -> kd.singletons.router.back()

    @mainView.addSubView view
