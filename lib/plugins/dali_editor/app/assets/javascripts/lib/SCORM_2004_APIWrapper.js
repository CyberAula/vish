/** **************************************************************************
SCORM_2004_APIwrapper.js
© 2000, 2011 Advanced Distributed Learning (ADL). Some Rights Reserved.
*****************************************************************************

Advanced Distributed Learning ("ADL") grants you ("Licensee") a  non-exclusive, 
royalty free, license to use and redistribute this  software in source and binary 
code form, provided that i) this copyright  notice and license appear on all 
copies of the software; and ii) Licensee does not utilize the software in a 
manner which is disparaging to ADL.

This software is provided "AS IS," without a warranty of any kind.  
ALL EXPRESS OR IMPLIED CONDITIONS, REPRESENTATIONS AND WARRANTIES, INCLUDING 
ANY IMPLIED WARRANTY OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR 
NON-INFRINGEMENT, ARE HEREBY EXCLUDED.  ADL AND ITS LICENSORS SHALL NOT BE LIABLE 
FOR ANY DAMAGES SUFFERED BY LICENSEE AS A RESULT OF USING, MODIFYING OR 
DISTRIBUTING THE SOFTWARE OR ITS DERIVATIVES.  IN NO EVENT WILL ADL OR ITS LICENSORS 
BE LIABLE FOR ANY LOST REVENUE, PROFIT OR DATA, OR FOR DIRECT, INDIRECT, SPECIAL, 
CONSEQUENTIAL, INCIDENTAL OR PUNITIVE DAMAGES, HOWEVER CAUSED AND REGARDLESS OF THE 
THEORY OF LIABILITY, ARISING OUT OF THE USE OF OR INABILITY TO USE SOFTWARE, EVEN IF 
ADL HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES.

*****************************************************************************
*SCORM_2004_APIwrapper.js code is licensed under the Creative Commons
Attribution-ShareAlike 3.0 Unported License.

To view a copy of this license:

     - Visit http://creativecommons.org/licenses/by-sa/3.0/ 
     - Or send a letter to
            Creative Commons, 444 Castro Street,  Suite 900, Mountain View,
            California, 94041, USA.

The following is a summary of the full license which is available at:

      - http://creativecommons.org/licenses/by-sa/3.0/legalcode

*****************************************************************************

Creative Commons Attribution-ShareAlike 3.0 Unported (CC BY-SA 3.0)

You are free to:

     - Share : to copy, distribute and transmit the work
     - Remix : to adapt the work

Under the following conditions:

     - Attribution: You must attribute the work in the manner specified by 
       the author or licensor (but not in any way that suggests that they 
       endorse you or your use of the work).

     - Share Alike: If you alter, transform, or build upon this work, you 
       may distribute the resulting work only under the same or similar 
       license to this one.

With the understanding that:

     - Waiver: Any of the above conditions can be waived if you get permission 
       from the copyright holder.

     - Public Domain: Where the work or any of its elements is in the public 
       domain under applicable law, that status is in no way affected by the license.

     - Other Rights: In no way are any of the following rights affected by the license:

           * Your fair dealing or fair use rights, or other applicable copyright 
             exceptions and limitations;

           * The author's moral rights;

           * Rights other persons may have either in the work itself or in how the 
             work is used, such as publicity or privacy rights.

     - Notice: For any reuse or distribution, you must make clear to others the 
               license terms of this work.

****************************************************************************/
/** *****************************************************************************
** Usage: Executable course content can call the API Wrapper
**      functions as follows:
**
**    javascript:
**          var result = doInitialize();
**          if (result != true) 
**          {
**             // handle error
**          }
**
**    authorware:
**          result := ReadURL("javascript:doInitialize()", 100)
**
**    director:
**          result = externalEvent("javascript:doInitialize()")
**
**
*******************************************************************************/

let debug = true; // set this to false to turn debugging off

let output = window.console; // output can be set to any object that has a log(string) function
// such as: var output = { log: function(str){alert(str);} };

// Define exception/error codes
let _NoError = { "code": "0", "string": "No Error", "diagnostic": "No Error" };
let _GeneralException = { "code": "101", "string": "General Exception", "diagnostic": "General Exception" };
let _AlreadyInitialized = { "code": "103", "string": "Already Initialized", "diagnostic": "Already Initialized" };

let initialized = false;

// local variable definitions
let apiHandle = null;

/** *****************************************************************************
**
** Function: doInitialize()
** Inputs:  None
** Return:  true if the initialization was successful, or
**          false if the initialization failed.
**
** Description:
** Initialize communication with LMS by calling the Initialize
** function which will be implemented by the LMS.
**
*******************************************************************************/
function doInitialize()
{
    if (initialized) {return "true";}

    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nInitialize was not successful.");
        return "false";
    }

    let result = api.Initialize("");

    if (result.toString() != "true")
    {
        let err = ErrorHandler();
        message("Initialize failed with error code: " + err.code);
    }
    else
    {
        initialized = true;
    }

    return result.toString();
}

/** *****************************************************************************
**
** Function doTerminate()
** Inputs:  None
** Return:  true if successful
**          false if failed.
**
** Description:
** Close communication with LMS by calling the Terminate
** function which will be implemented by the LMS
**
*******************************************************************************/
function doTerminate()
{
    if (! initialized) {return "true";}

    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nTerminate was not successful.");
        return "false";
    }

    // call the Terminate function that should be implemented by the API
    let result = api.Terminate("");
    if (result.toString() != "true")
    {
        let err = ErrorHandler();
        message("Terminate failed with error code: " + err.code);
    }

    initialized = false;

    return result.toString();
}

/** *****************************************************************************
**
** Function doGetValue(name)
** Inputs:  name - string representing the cmi data model defined category or
**             element (e.g. cmi.learner_id)
** Return:  The value presently assigned by the LMS to the cmi data model
**       element defined by the element or category identified by the name
**       input value.
**
** Description:
** Wraps the call to the GetValue method
**
*******************************************************************************/
function doGetValue(name)
{
    let api = getAPIHandle();
    let result = "";
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nGetValue was not successful.");
    }
    else if (!initialized && ! doInitialize())
    {
        let err = ErrorHandler();
        message("GetValue failed - Could not initialize communication with the LMS - error code: " + err.code);
    }
    else
    {
        result = api.GetValue(name);

        let error = ErrorHandler();
        if (error.code != _NoError.code)
        {
            // an error was encountered so display the error description
            message("GetValue(" + name + ") failed. \n" + error.code + ": " + error.string);
            result = "";
        }
    }
    return result.toString();
}

/** *****************************************************************************
**
** Function doSetValue(name, value)
** Inputs:  name -string representing the data model defined category or element
**          value -the value that the named element or category will be assigned
** Return:  true if successful
**          false if failed.
**
** Description:
** Wraps the call to the SetValue function
**
*******************************************************************************/
function doSetValue(name, value)
{
    let api = getAPIHandle();
    let result = "false";
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nSetValue was not successful.");
    }
    else if (!initialized && !doInitialize())
    {
        let error = ErrorHandler();
        message("SetValue failed - Could not initialize communication with the LMS - error code: " + error.code);
    }
    else
    {
        result = api.SetValue(name, value);
        if (result.toString() != "true")
        {
            let err = ErrorHandler();
            message("SetValue(" + name + ", " + value + ") failed. \n" + err.code + ": " + err.string);
        }
    }

    return result.toString();
}

/** *****************************************************************************
**
** Function doCommit()
** Inputs:  None
** Return:  true if successful
**          false if failed
**
** Description:
** Commits the data to the LMS. 
**
*******************************************************************************/
function doCommit()
{
    let api = getAPIHandle();
    let result = "false";
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nCommit was not successful.");
    }
    else if (!initialized && ! doInitialize())
    {
        let error = ErrorHandler();
        message("Commit failed - Could not initialize communication with the LMS - error code: " + error.code);
    }
    else
    {
        result = api.Commit("");
        if (result != "true")
        {
            let err = ErrorHandler();
            message("Commit failed - error code: " + err.code);
        }
    }

    return result.toString();
}

/** *****************************************************************************
**
** Function doGetLastError()
** Inputs:  None
** Return:  The error code that was set by the last LMS function call
**
** Description:
** Call the GetLastError function 
**
*******************************************************************************/
function doGetLastError()
{
    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nGetLastError was not successful.");
        // since we can't get the error code from the LMS, return a general error
        return _GeneralException.code;
    }

    return api.GetLastError().toString();
}

/** *****************************************************************************
**
** Function doGetErrorString(errorCode)
** Inputs:  errorCode - Error Code
** Return:  The textual description that corresponds to the input error code
**
** Description:
** Call the GetErrorString function 
**
********************************************************************************/
function doGetErrorString(errorCode)
{
    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nGetErrorString was not successful.");
        return _GeneralException.string;
    }

    return api.GetErrorString(errorCode).toString();
}

/** *****************************************************************************
**
** Function doGetDiagnostic(errorCode)
** Inputs:  errorCode - Error Code(integer format), or null
** Return:  The vendor specific textual description that corresponds to the 
**          input error code
**
** Description:
** Call the LMSGetDiagnostic function
**
*******************************************************************************/
function doGetDiagnostic(errorCode)
{
    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nGetDiagnostic was not successful.");
        return "Unable to locate the LMS's API Implementation. GetDiagnostic was not successful.";
    }

    return api.GetDiagnostic(errorCode).toString();
}

/** *****************************************************************************
**
** Function ErrorHandler()
** Inputs:  None
** Return:  The current error
**
** Description:
** Determines if an error was encountered by the previous API call
** and if so, returns the error.
**
** Usage:
** var last_error = ErrorHandler();
** if (last_error.code != _NoError.code)
** {
**    message("Encountered an error. Code: " + last_error.code + 
**                                "\nMessage: " + last_error.string +
**                                "\nDiagnostics: " + last_error.diagnostic);
** }
*******************************************************************************/
function ErrorHandler()
{
    let error = { "code": _NoError.code, "string": _NoError.string, "diagnostic": _NoError.diagnostic };
    let api = getAPIHandle();
    if (api == null)
    {
        message("Unable to locate the LMS's API Implementation.\nCannot determine LMS error code.");
        error.code = _GeneralException.code;
        error.string = _GeneralException.string;
        error.diagnostic = "Unable to locate the LMS's API Implementation. Cannot determine LMS error code.";
        return error;
    }

    // check for errors caused by or from the LMS
    error.code = api.GetLastError().toString();
    if (error.code != _NoError.code)
    {
        // an error was encountered so display the error description
        error.string = api.GetErrorString(error.code);
        error.diagnostic = api.GetDiagnostic("");
    }

    return error;
}

/** ****************************************************************************
**
** Function getAPIHandle()
** Inputs:  None
** Return:  value contained by APIHandle
**
** Description:
** Returns the handle to API object if it was previously set,
** otherwise it returns null
**
*******************************************************************************/
function getAPIHandle()
{
    if (apiHandle == null)
    {
        apiHandle = getAPI();
    }

    return apiHandle;
}

/** *****************************************************************************
**
** Function findAPI(win)
** Inputs:  win - a Window Object
** Return:  If an API object is found, it's returned, otherwise null is returned
**
** Description:
** This function looks for an object named API_1484_11 in parent and opener
** windows
**
*******************************************************************************/
function findAPI(win)
{
    let findAPITries = 0;
    while ((win.API_1484_11 == null) && (win.parent != null) && (win.parent != win))
    {
        findAPITries++;

        if (findAPITries > 500)
        {
            message("Error finding API -- too deeply nested.");
            return null;
        }

        win = win.parent;

    }
    return win.API_1484_11;
}

/** *****************************************************************************
**
** Function getAPI()
** Inputs:  none
** Return:  If an API object is found, it's returned, otherwise null is returned
**
** Description:
** This function looks for an object named API_1484_11, first in the current window's 
** frame hierarchy and then, if necessary, in the current window's opener window
** hierarchy (if there is an opener window).
**
*******************************************************************************/
function getAPI()
{
    let theAPI = findAPI(window);
    if ((theAPI == null) && (window.opener != null) && (typeof(window.opener) !== "undefined"))
    {
        theAPI = findAPI(window.opener);
    }
    if (theAPI == null)
    {
        message("Unable to find an API adapter");
    }
    return theAPI;
}

/** *****************************************************************************
**
** Function findObjective(objId)
** Inputs:  objId - the id of the objective
** Return:  the index where this objective is located 
**
** Description:
** This function looks for the objective within the objective array and returns 
** the index where it was found or it will create the objective for you and return 
** the new index.
**
*******************************************************************************/
function findObjective(objId)
{
    let num = doGetValue("cmi.objectives._count");
    let objIndex = -1;

    for (let i = 0; i < num; ++i) {
        if (doGetValue("cmi.objectives." + i + ".id") == objId) {
            objIndex = i;
            break;
        }
    }

    if (objIndex == -1) {
        message("Objective " + objId + " not found.");
        objIndex = num;
        message("Creating new objective at index " + objIndex);
        doSetValue("cmi.objectives." + objIndex + ".id", objId);
    }
    return objIndex;
}

/** *****************************************************************************
** NOTE: This is a SCORM 2004 4th Edition feature.
*
** Function findDataStore(id)
** Inputs:  id - the id of the data store
** Return:  the index where this data store is located or -1 if the id wasn't found
**
** Description:
** This function looks for the data store within the data array and returns 
** the index where it was found or returns -1 to indicate the id wasn't found 
** in the collection.
**
** Usage:
** var dsIndex = findDataStore("myds");
** if (dsIndex > -1)
** {
**    doSetValue("adl.data." + dsIndex + ".store", "save this info...");
** }
** else
** {
**    var appending_data = doGetValue("cmi.suspend_data");
**    doSetValue("cmi.suspend_data", appending_data + "myds:save this info");
** }
*******************************************************************************/
function findDataStore(id)
{
    let num = doGetValue("adl.data._count");
    let index = -1;

    // if the get value was not null and is a number 
    // in other words, we got an index in the adl.data array
    if (num != null && ! isNaN(num))
    {
        for (let i = 0; i < num; ++i)
        {
            if (doGetValue("adl.data." + i + ".id") == id)
            {
                index = i;
                break;
            }
        }

        if (index == -1)
        {
            message("Data store " + id + " not found.");
        }
    }

    return index;
}

/** *****************************************************************************
**
** Function message(str)
** Inputs:  String - message you want to send to the designated output
** Return:  none
** Depends on: boolean debug to indicate if output is wanted
**             object output to handle the messages. must implement a function 
**             log(string)
**
** Description:
** This function outputs messages to a specified output. You can define your own 
** output object. It will just need to implement a log(string) function. This 
** interface was used so that the output could be assigned the window.console object.
*******************************************************************************/
function message(str)
{
    if(debug)
    {
        output.log(str);
    }
}
