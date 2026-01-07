#!/bin/bash
cd src || { echo "Error"; exit 1; }

echo "Start"

echo "Removing ..."
rm -f App.idr Config.idr Core/Interfaces.idr Core/Manager.idr Core/Models.idr Core/Effects.idr
echo "Removing unnecessary files"
rm -f Plugins/Auditing/ConsoleLogger.idr
rm -f Plugins/Auditing/FileLogger.idr
rm -f Plugins/Authentication/JWTAuth.idr
rm -f Plugins/Authentication/StaticUserAuth.idr
rm -f Plugins/Authorization/ABAC.idr
rm -f Plugins/Authorization/RBAC.idr
echo "Doing correct location..."
mv -f Plugins/Authentication/EnhancedABAC.idr Plugins/Authorization/EnhancedABAC.idr
mv -f Plugins/Authentication/EnhancedRBAC.idr Plugins/Authorization/EnhancedRBAC.idr
echo "Renaming"
mv -f Data/AVLtree.idr Data/AVLTree.idr
echo "Cleanup complete"

cd ..
