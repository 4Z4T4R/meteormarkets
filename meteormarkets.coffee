Claims = new Mongo.Collection "claims"

if Meteor.isClient
  angular.module "mm-claims", ['angular-meteor']
  
  onReady = () ->
    angular.bootstrap document, ['mm-claims']

  if Meteor.isCordova
    angular.element(document).on 'deviceready', onReady
  else
    angular.element(document).ready onReady

  angular.module("mm-claims").controller "MMClaimsCtrl", [
    '$scope', '$meteor',
    ($scope, $meteor) ->
      $scope.$meteorSubscribe 'claims'
      $scope.claims = $meteor.collection () ->
        return Claims.find $scope.getReactively('query'), sort: createdAt: -1 

      $scope.addClaim = (newClaim) ->
        $meteor.call 'addClaim', newClaim
      $scope.deleteClaim = (claim) ->
        $meteor.call 'deleteClaim', claim._id
      $scope.setChecked = (claim) ->
        $meteor.call 'setChecked', claim._id, !claim.checked
      $scope.setPrivate = (claim) ->
        $meteor.call 'setPrivate', claim._id, !claim.private

      $scope.incompleteCount = () ->
        return Claims.find(checked: $ne: true).count()

      $scope.$watch 'hideCompleted', () ->
        if $scope.hideCompleted
          $scope.query = checked: $ne: true
        else
          $scope.query = {}
  ]

  Accounts.ui.config {
    passwordSignupFields: "USERNAME_ONLY"
  }

if Meteor.isServer
  Meteor.startup () ->
    # code to run on server at startup
    Meteor.publish 'claims', () ->
      return Claims.find {
        $or: [
          { private: $ne: true }
          { owner: @userId }
        ]
      }

Meteor.methods {
  addClaim: (text) ->
    # Make sure they're logged in.
    if not Meteor.userId()
      throw new Meteor.error 'not-authorized'
    Claims.insert {
      text: text,
      createdAt: new Date()
      owner: Meteor.userId()
      username: Meteor.user().username
    }
  deleteClaim: (claimId) ->
    Claims.remove(claimId)
  setChecked: (claimId, setChecked) ->
    Claims.update(claimId, { $set: checked: setChecked })
  setPrivate: (claimId, setToPrivate) ->
    claim = Claims.findOne claimId
    if claim.owner != Meteor.userId()
      throw new Meteor.Error 'not-authorized'
    Claims.update claimId, { $set: private: setToPrivate }
}
