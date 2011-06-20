/*=========================================================================

  Program:   Visualization Toolkit
  Module:    vtkProgramShader.cxx

  Copyright (c) Ken Martin, Will Schroeder, Bill Lorensen
  All rights reserved.
  See Copyright.txt or http://www.kitware.com/Copyright.htm for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.  See the above copyright notice for more information.

=========================================================================*/
#include "vtkProgramShader.h"

// --------------------------------------------------------------------includes
#include <iostream>

// -----------------------------------------------------------------------macro

// --------------------------------------------------------------------internal
// IMPORTANT: Make sure that this struct has no pointers.  All pointers should
// be put in the class declaration. For all newly defined pointers make sure to
// update constructor and destructor methods.
struct vtkProgramShaderInternal
{
  double value; // sample
};

// -----------------------------------------------------------------------cnstr
vtkProgramShader::vtkProgramShader()
{
  this->Internal = new vtkProgramShaderInternal();
}

// -----------------------------------------------------------------------destr
vtkProgramShader::~vtkProgramShader()
{
  delete this->Internal;
}

bool vtkProgramShader::Read()
{
  std::cout << "Read: vtkProgramShader" << std::endl;
  return true;
}

void vtkProgramShader::Render(vtkPainter *render)
{
  std::cout << "Render vtkProgramShader" << std::endl;
}


