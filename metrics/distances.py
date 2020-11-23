#!/usr/bin/env python

# Copyright (c) 2020 Computer Vision Center (CVC) at the Universitat Autonoma de
# Barcelona (UAB).
#
# This work is licensed under the terms of the MIT license.
# For a copy, see <https://opensource.org/licenses/MIT>.

"""
This metric calculates the distance between the ego vehicle and
another actor, dumping it to a json file.

It is meant to serve as an example of how to use the information from
the recorder
"""

import math
import base64
from io import BytesIO
from matplotlib.figure import Figure

from srunner.metrics.examples.basic_metric import BasicMetric


class DistanceBetweenVehicles(BasicMetric):
    """
    Metric class DistanceBetweenVehicles
    """

    def _create_metric(self, town_map, log, criteria):
        """
        Implementation of the metric. This is an example to show how to use the recorder,
        accessed via the log.
        """

        # Get the ID of the two vehicles
        ego_id = log.get_ego_vehicle_id()
        adv_id = log.get_actor_ids_with_role_name("scenario")[0]  # Could have also used its type_id

        dist_list = []
        frames_list = []

        # Get the frames both actors were alive
        start_ego, end_ego = log.get_actor_alive_frames(ego_id)
        start_adv, end_adv = log.get_actor_alive_frames(adv_id)
        start = max(start_ego, start_adv)
        end = min(end_ego, end_adv)

        # Get the distance between the two
        for i in range(start, end):

            # Get the transforms
            ego_location = log.get_actor_transform(ego_id, i).location
            adv_location = log.get_actor_transform(adv_id, i).location

            # Filter some points for a better graph
            if adv_location.z < -10:
                continue

            dist_v = ego_location - adv_location
            dist = math.sqrt(dist_v.x * dist_v.x + dist_v.y * dist_v.y + dist_v.z * dist_v.z)

            dist_list.append(dist)
            frames_list.append(i)

        # Use matplotlib to show the results
        fig = Figure()
        ax = fig.subplots()
        ax.plot(frames_list, dist_list)
        ax.set_ylabel('Distance [m]')
        ax.set_xlabel('Frame number')
        ax.set_title('Distance between the ego vehicle and the adversary over time')

        buf = BytesIO()
        fig.savefig(buf, format="png")

        data = base64.b64encode(buf.getbuffer()).decode("ascii");
        print(data)

        dist_list = []
        frames_list = []

        # Get the projected distance vector to the center of the lane
        for i in range(start_ego, end_ego + 1):

            ego_location = log.get_actor_transform(ego_id, i).location
            ego_waypoint = town_map.get_waypoint(ego_location)

            # Get the distance vector and project it
            a = ego_location - ego_waypoint.transform.location      # Ego to waypoint vector
            b = ego_waypoint.transform.get_right_vector()           # Waypoint perpendicular vector
            b_norm = math.sqrt(b.x * b.x + b.y * b.y + b.z * b.z)

            ab_dot = a.x * b.x + a.y * b.y + a.z * b.z
            dist_v = ab_dot/(b_norm*b_norm)*b
            dist = math.sqrt(dist_v.x * dist_v.x + dist_v.y * dist_v.y + dist_v.z * dist_v.z)

            # Get the sign of the distance (left side is positive)
            c = ego_waypoint.transform.get_forward_vector()         # Waypoint forward vector
            ac_cross = c.x * a.y - c.y * a.x
            if ac_cross < 0:
                dist *= -1

            dist_list.append(dist)
            frames_list.append(i)

        # Use matplotlib to show the results

        fig = Figure()
        ax = fig.subplots()
        ax.plot(frames_list, dist_list)
        ax.set_ylabel('Distance [m]')
        ax.set_xlabel('Frame number')
        ax.set_title('Distance from the ego vehicle to lane center over time')

        buf = BytesIO()
        fig.savefig(buf, format="png")

        data = base64.b64encode(buf.getbuffer()).decode("ascii");
        print(data)

