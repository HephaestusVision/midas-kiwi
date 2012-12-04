/*========================================================================
  VES --- VTK OpenGL ES Rendering Toolkit

      http://www.kitware.com/ves

  Copyright 2011 Kitware, Inc.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

      http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
 ========================================================================*/
/// \class vesKiwiAnimationRepresentation
/// \ingroup KiwiPlatform
#ifndef __vesKiwiAnimationRepresentation_h
#define __vesKiwiAnimationRepresentation_h

#include "vesKiwiWidgetRepresentation.h"

class vesShaderProgram;
class vesKiwiPolyDataRepresentation;

class vesKiwiAnimationRepresentation : public vesKiwiWidgetRepresentation
{
public:

  typedef vesKiwiWidgetRepresentation Superclass;
  vesKiwiAnimationRepresentation();
  ~vesKiwiAnimationRepresentation();

  void initializeWithShader(vesSharedPtr<vesShaderProgram> geometryShader, 
    vesSharedPtr<vesShaderProgram> textureShader,
    vesSharedPtr<vesShaderProgram> gouraudTextureShader);

  void loadData(const std::string& filename);

  virtual void addSelfToRenderer(vesSharedPtr<vesRenderer> renderer);
  virtual void removeSelfFromRenderer(vesSharedPtr<vesRenderer> renderer);
  virtual void willRender(vesSharedPtr<vesRenderer> renderer);

  virtual bool handleSingleTouchTap(int displayX, int displayY);
  virtual bool handleSingleTouchDown(int displayX, int displayY);
  virtual bool handleSingleTouchPanGesture(double deltaX, double deltaY);
  virtual bool handleSingleTouchUp();

protected:

  vesKiwiPolyDataRepresentation* currentFrameRepresentation();

private:

  vesKiwiAnimationRepresentation(const vesKiwiAnimationRepresentation&); // Not implemented
  void operator=(const vesKiwiAnimationRepresentation&); // Not implemented

  class vesInternal;
  vesInternal* Internal;
};

#endif
