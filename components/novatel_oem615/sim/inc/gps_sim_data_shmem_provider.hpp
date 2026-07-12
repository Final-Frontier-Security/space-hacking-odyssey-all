/* Copyright (C) 2015 - 2025 National Aeronautics and Space Administration. All Foreign Rights are Reserved to the U.S. Government.

   This software is provided "as is" without any warranty of any, kind either express, implied, or statutory, including, but not
   limited to, any warranty that the software will conform to, specifications any implied warranties of merchantability, fitness
   for a particular purpose, and freedom from infringement, and any warranty that the documentation will conform to the program, or
   any warranty that the software will be error free.

   In no event shall NASA be liable for any damages, including, but not limited to direct, indirect, special or consequential damages,
   arising out of, resulting from, or in any way connected with the software or its documentation.  Whether or not based upon warranty,
   contract, tort or otherwise, and whether or not loss was sustained from, or arose out of the results of, or use of, the software,
   documentation or services provided hereunder

   ITC Team
   NASA IV&V
   ivv-itc@lists.nasa.gov
*/

#ifndef NOS3_GPS_SIM_DATA_SHMEM_PROVIDER_HPP
#define NOS3_GPS_SIM_DATA_SHMEM_PROVIDER_HPP

//#include <vector>

//#include <Client/Bus.hpp>

#include <boost/interprocess/managed_shared_memory.hpp>
#include <sim_i_data_provider.hpp>
#include <blackboard_data.hpp>

namespace Nos3
{
    namespace bip = boost::interprocess;

    /** \brief Class for a provider of GPS simulation data that provides data from a shared memory connection to 42.
     *
     */
    class GPSSimDataShmemProvider : public SimIDataProvider
    {
    public:
        /// @name Constructors / destructors
        //@{
        /// \brief Constructor taking a configuration object.
        /// @param  config  The configuration for the simulation
        GPSSimDataShmemProvider(const boost::property_tree::ptree& config);
        //@}

        /// @name Non-mutating public worker methods
        //@{
        /** \brief Method to retrieve GPS data.
         *
         * @returns                     A data point of GPS data.
         */
      virtual boost::shared_ptr<SimIDataPoint> get_data_point(void) const;
        //@}
    private:
        // Private helper methods
        // Private data
        int16_t _sc;  // Which spacecraft number to parse out of 42 data
        int16_t _gps; // Which GPS number to parse out of 42 data
        int16_t _leap_seconds; // Current number of leap seconds

        bip::mapped_region _shm_region;
        BlackboardData*    _blackboard_data;
    };
}

#endif
