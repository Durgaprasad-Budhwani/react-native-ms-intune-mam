using ReactNative.Bridge;
using System;
using System.Collections.Generic;
using Windows.ApplicationModel.Core;
using Windows.UI.Core;

namespace Com.Reactlibrary.RNReactNativeMsIntuneMam
{
    /// <summary>
    /// A module that allows JS to share data.
    /// </summary>
    class RNReactNativeMsIntuneMamModule : NativeModuleBase
    {
        /// <summary>
        /// Instantiates the <see cref="RNReactNativeMsIntuneMamModule"/>.
        /// </summary>
        internal RNReactNativeMsIntuneMamModule()
        {

        }

        /// <summary>
        /// The name of the native module.
        /// </summary>
        public override string Name
        {
            get
            {
                return "RNReactNativeMsIntuneMam";
            }
        }
    }
}
