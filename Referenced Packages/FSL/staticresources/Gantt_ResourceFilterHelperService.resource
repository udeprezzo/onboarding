'use strict';

(function () {

    angular.module('serviceExpert').factory('resourceFilterHelper', ['$q', 'sfdcService', '$sce', function ($q, sfdcService, $sce) {

        var __resourceFieldset = null,
            __picklistNames = null,
            __selectionInfo = {
            selectedPicklist: null,
            resourceFilteringOptions: {},
            picklistOptionsModel: [],
            picklistOptions: [],
            picklistNullValues: false
        };

        // get metadata of resource fieldset
        var fieldsetMetadataPromise = sfdcService.getResourceFieldSetFields().then(function (fieldset) {

            // INDEX: 0: Label, 1: Type (BOOLEAN or PICKLIST, 2: Developer name (*****__c)
            __resourceFieldset = fieldset;

            __resourceFieldset.Name = ["Name", "STRING", "Name"];

            for (var fieldName in __resourceFieldset) {
                if (__resourceFieldset[fieldName][1] === 'BOOLEAN') {
                    __selectionInfo.resourceFilteringOptions[fieldName] = false;
                }
            }
        });

        fieldsetMetadataPromise.then(function () {

            var picklistNames = [];

            for (var fieldName in __resourceFieldset) {
                if (__resourceFieldset[fieldName][1] === 'PICKLIST') {
                    picklistNames.push(fieldName);
                }
            }

            sfdcService.getResourcePicklistValues(picklistNames).then(function (names) {
                __picklistNames = names;
            });
        });

        function getResourceFieldset() {
            return __resourceFieldset;
        }

        function getPicklistNames() {
            return __picklistNames;
        }

        function updateSelectedPicklist(field, onOrOff) {

            var indexOfField = __selectionInfo.picklistOptions.indexOf(field);

            // add selected value of picklist
            if (indexOfField === -1) {
                __selectionInfo.picklistOptions.push(field);
            }

            // removing...
            else {
                    __selectionInfo.picklistOptions.splice(indexOfField, 1);
                }
        }

        function isResourceFilterApplied() {

            // is picklist selected?
            if (__selectionInfo.selectedPicklist && (__selectionInfo.picklistOptions.length || __selectionInfo.picklistNullValues)) return true;

            // is boolean selected?
            for (var field in __selectionInfo.resourceFilteringOptions) {
                if (__selectionInfo.resourceFilteringOptions[field]) {
                    return true;
                }
            }

            return false;
        }

        function resetFilter() {
            __selectionInfo.selectedPicklist = 'select_a_field';
            __selectionInfo.length = 0;
            __selectionInfo.picklistOptions.length = 0;
            __selectionInfo.picklistNullValues = false;

            for (var field in __selectionInfo.resourceFilteringOptions) {
                __selectionInfo.resourceFilteringOptions[field] = false;
            }
        }

        function setAll() {
            for (var field in __selectionInfo.resourceFilteringOptions) {
                __selectionInfo.resourceFilteringOptions[field] = true;
            }
        }

        function generateFilterExplanation(workingResources) {

            var booleanDescription = '',
                pikclistDescription = '',
                generatedExplanation = customLabels.SelectAfieldToResourceFilter;

            if (workingResources) {
                booleanDescription = '<b>' + customLabels.CurrentlyWorking + '</b>';
            }

            for (var field in __resourceFieldset) {

                if (__resourceFieldset[field][1] === 'BOOLEAN' && __selectionInfo.resourceFilteringOptions[__resourceFieldset[field][2]]) {

                    if (booleanDescription === '') {
                        booleanDescription = '<b>' + __resourceFieldset[field][0] + '</b>';
                    } else {
                        booleanDescription += ' and <b>' + __resourceFieldset[field][0] + '</b>';
                    }
                } else if (__resourceFieldset[field][1] === 'PICKLIST' && __selectionInfo.selectedPicklist === __resourceFieldset[field][2]) {

                    pikclistDescription = __selectionInfo.picklistOptions.join('</b> ' + customLabels.or + ' <b>');

                    if (pikclistDescription.length > 0) {
                        pikclistDescription = '<b>' + __resourceFieldset[field][0] + '</b> is <b>' + pikclistDescription + '</b>';
                    }

                    if (__selectionInfo.picklistNullValues) {
                        if (pikclistDescription === '') {
                            pikclistDescription = '<b>' + customLabels.None + '</b>';
                        } else {
                            pikclistDescription += ' ' + customLabels.or + ' <b>' + customLabels.None + '</b>';
                        }
                    }
                }
            }

            if (booleanDescription !== '' && pikclistDescription !== '') {
                generatedExplanation = customLabels.Resources_That_Are_x_and_y.replaceAll(booleanDescription, pikclistDescription);
            } else if (booleanDescription === '' && pikclistDescription !== '') {
                generatedExplanation = customLabels.Resources_That_Are_x.replaceAll(pikclistDescription);
            } else if (booleanDescription !== '' && pikclistDescription == '') {
                generatedExplanation = customLabels.Resources_That_Are_x.replaceAll(booleanDescription);
            }

            //return $sce.trustAsHtml(generatedExplanation);
            return generatedExplanation;
        }

        // service object
        return {
            getResourceFieldset: getResourceFieldset,
            getPicklistNames: getPicklistNames,
            selectionInfo: __selectionInfo,
            updateSelectedPicklist: updateSelectedPicklist,
            resetFilter: resetFilter,
            setAll: setAll,
            generateFilterExplanation: generateFilterExplanation,
            isResourceFilterApplied: isResourceFilterApplied,
            resourceFieldToSortyBy: 'Name',
            descending: true
        };
    }]);
})();