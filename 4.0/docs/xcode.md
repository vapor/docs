# Xcode

## Setting a Custom Working Directory
By default Xcode will reference a very obscure working directory called DerivedData for various assets which can cause significant problems or confusion. To avoid this, set a *Custom Working Directory* in the Xcode Scheme for your project. 

You will notice it is *not* set when you see this warning in the output: 
![Output Warning](images/set-working-dir-01.png)

Edit the scheme and set it to your project's folder:  
![Edit Scheme](images/set-working-dir-02.png)

Set the Custom Working directory...
(before)
![Before Setting](images/set-working-dir-03.png)


(after)
![After Setting](images/set-working-dir-05.png)

Click "Close" to save the change. 
You will need to do this once for each Vapor project. 




