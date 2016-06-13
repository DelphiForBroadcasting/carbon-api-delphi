unit CARBONCOMDLLLib_TLB;

// ************************************************************************ //
// WARNING                                                                    
// -------                                                                    
// The types declared in this file were generated from data read from a       
// Type Library. If this type library is explicitly or indirectly (via        
// another type library referring to this type library) re-imported, or the   
// 'Refresh' command of the Type Library Editor activated while editing the   
// Type Library, the contents of this file will be regenerated and all        
// manual modifications will be lost.                                         
// ************************************************************************ //

// $Rev: 52393 $
// File generated on 27.05.2016 19:47:12 from Type Library described below.

// ************************************************************************  //
// Type Lib: C:\Program Files (x86)\Common Files\Rhozet\Carbon Coder\Kernel\CARBONCOMDLL.dll (1)
// LIBID: {F07F040B-AFE9-422B-B064-ADCCB447714E}
// LCID: 0
// Helpfile: 
// HelpString: CarbonCOMDLL 1.0 Type Library
// DepndLst: 
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers. 
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, System.Variants, System.Win.StdVCL, Vcl.Graphics, Vcl.OleServer, Winapi.ActiveX;
  

// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:        
//   Type Libraries     : LIBID_xxxx                                      
//   CoClasses          : CLASS_xxxx                                      
//   DISPInterfaces     : DIID_xxxx                                       
//   Non-DISP interfaces: IID_xxxx                                        
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  CARBONCOMDLLLibMajorVersion = 1;
  CARBONCOMDLLLibMinorVersion = 0;

  LIBID_CARBONCOMDLLLib: TGUID = '{F07F040B-AFE9-422B-B064-ADCCB447714E}';

  IID_ICarbonCOMInterface: TGUID = '{54F44E58-F7B2-4075-94BE-B9F99F321847}';
  CLASS_CarbonCOMInterface: TGUID = '{4426184F-BEFB-40D7-9987-0498CD6AC434}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary                    
// *********************************************************************//
  ICarbonCOMInterface = interface;
  ICarbonCOMInterfaceDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library                       
// (NOTE: Here we map each CoClass to its Default Interface)              
// *********************************************************************//
  CarbonCOMInterface = ICarbonCOMInterface;


// *********************************************************************//
// Interface: ICarbonCOMInterface
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {54F44E58-F7B2-4075-94BE-B9F99F321847}
// *********************************************************************//
  ICarbonCOMInterface = interface(IDispatch)
    ['{54F44E58-F7B2-4075-94BE-B9F99F321847}']
    procedure QueryCarbonStatus; safecall;
    procedure CarbonCommand(const bstrCommand: WideString; out bstrReturn: WideString); safecall;
    procedure CarbonCommandNET(const bstrMachine: WideString; const bstrCommand: WideString; 
                               out bstrReturn: WideString); safecall;
  end;

// *********************************************************************//
// DispIntf:  ICarbonCOMInterfaceDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {54F44E58-F7B2-4075-94BE-B9F99F321847}
// *********************************************************************//
  ICarbonCOMInterfaceDisp = dispinterface
    ['{54F44E58-F7B2-4075-94BE-B9F99F321847}']
    procedure QueryCarbonStatus; dispid 1;
    procedure CarbonCommand(const bstrCommand: WideString; out bstrReturn: WideString); dispid 2;
    procedure CarbonCommandNET(const bstrMachine: WideString; const bstrCommand: WideString; 
                               out bstrReturn: WideString); dispid 3;
  end;

// *********************************************************************//
// The Class CoCarbonCOMInterface provides a Create and CreateRemote method to          
// create instances of the default interface ICarbonCOMInterface exposed by              
// the CoClass CarbonCOMInterface. The functions are intended to be used by             
// clients wishing to automate the CoClass objects exposed by the         
// server of this typelibrary.                                            
// *********************************************************************//
  CoCarbonCOMInterface = class
    class function Create: ICarbonCOMInterface;
    class function CreateRemote(const MachineName: string): ICarbonCOMInterface;
  end;

implementation

uses System.Win.ComObj;

class function CoCarbonCOMInterface.Create: ICarbonCOMInterface;
begin
  Result := CreateComObject(CLASS_CarbonCOMInterface) as ICarbonCOMInterface;
end;

class function CoCarbonCOMInterface.CreateRemote(const MachineName: string): ICarbonCOMInterface;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_CarbonCOMInterface) as ICarbonCOMInterface;
end;

end.
