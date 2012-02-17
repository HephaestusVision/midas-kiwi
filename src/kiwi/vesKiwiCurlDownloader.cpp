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

#include "vesKiwiCurlDownloader.h"

#include <curl/curl.h>
#include <fstream>

namespace {


size_t header_function(char *buffer, size_t size, size_t nmemb, void *userData)
{
  size_t totalSize = size*nmemb;
  std::string header(buffer, totalSize);

  if (header.find("Content-Disposition:") != std::string::npos)
    {
    size_t start = header.find("filename=\"");
    size_t end = header.find("\"", start+10);

    if (start != std::string::npos && end != std::string::npos)
      {
      std::string filename = header.substr(start+10, end-(start+10));
      vesKiwiCurlDownloader* downloader = static_cast<vesKiwiCurlDownloader*>(userData);
      downloader->setAttachmentFileName(filename);
      }
    }
  return totalSize;
}

size_t write_file(char *buffer, size_t size, size_t nmemb, void *userData)
{
  size_t totalSize = size*nmemb;
  std::ofstream& outFile = *static_cast<std::ofstream*>(userData);
  outFile.write(buffer, totalSize);
  if (outFile.bad()) {
    return 0;
  }
  return totalSize;
}

}

vesKiwiCurlDownloader::vesKiwiCurlDownloader()
{
  this->m_curl = curl_easy_init();
  if (!this->m_curl) {
    this->setError("cURL Error", "There was an error initializing cURL.");
  }
}

vesKiwiCurlDownloader::~vesKiwiCurlDownloader()
{
  curl_easy_cleanup(this->m_curl);
}

bool vesKiwiCurlDownloader::downloadFile(const std::string& url, const std::string& destFile)
{
  if (!m_curl) {
    return false;
  }

  std::ofstream outFile;
  outFile.open(destFile.c_str(), std::ios::out | std::ios::trunc | std::ios::binary);

  if (!outFile.is_open()) {
    this->setError("File Error", "Could not open file for writing.");
    return false;
  }

  curl_easy_setopt(m_curl, CURLOPT_URL, url.c_str());

  curl_easy_setopt(m_curl, CURLOPT_HEADERFUNCTION, header_function);
  curl_easy_setopt(m_curl, CURLOPT_HEADERDATA, this);

  curl_easy_setopt(m_curl, CURLOPT_WRITEFUNCTION, write_file);
  curl_easy_setopt(m_curl, CURLOPT_WRITEDATA, &outFile);

  CURLcode result = curl_easy_perform(m_curl);

  outFile.close();

  if (result != CURLE_OK) {
    this->setError("Download Error", curl_easy_strerror(result));
    return false;
  }

  long responseCode;
  result = curl_easy_getinfo(m_curl, CURLINFO_RESPONSE_CODE, &responseCode);

  if (result == CURLE_OK && responseCode == 200) {
    return true;
  }

  this->setError("Download Error", "Error downloading url: " + url);
  return false;
}
